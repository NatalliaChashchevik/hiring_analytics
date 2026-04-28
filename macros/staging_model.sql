{% macro staging_model(
    raw_table,
    source_name          = 'raw',
    materialized         = 'table',
    unique_key           = 'ID',
    incremental_strategy = 'merge',
    on_schema_change     = 'append_new_columns'
) %}

{%- set _cfg_ref = ref('configuration') -%}

{%- set ns = namespace(
    alias            = 'stg_' ~ raw_table | lower,
    updated_col      = '_UPDATED_MICROS',
    business_key_raw = 'ID',
    columns          = []
) -%}

{%- if execute -%}

    {%- set _cfg_query -%}
        SELECT
            RAW_COLUMN_NAME,
            TARGET_TABLE_NAME,
            TARGET_COLUMN_NAME,
            UPPER(TARGET_DATA_TYPE) AS TARGET_DATA_TYPE
        FROM {{ _cfg_ref }}
        WHERE UPPER(RAW_TABLE_NAME) = UPPER('{{ raw_table }}')
          AND RAW_COLUMN_NAME  IS NOT NULL
          AND TRIM(RAW_COLUMN_NAME) <> ''
        ORDER BY TARGET_ORDER_NUM ASC
    {%- endset -%}

    {%- set _result = run_query(_cfg_query) -%}
    {%- set ns.columns = _result.rows -%}

    {%- if ns.columns | length > 0 -%}
        {%- set ns.alias = ns.columns[0]['TARGET_TABLE_NAME'] | lower -%}
    {%- endif -%}

    {%- if ns.columns | length > 1 -%}
        {%- set ns.business_key_raw = ns.columns[1]['RAW_COLUMN_NAME'] -%}
    {%- endif -%}

    {%- for row in ns.columns -%}
        {%- if row['TARGET_COLUMN_NAME'] == 'UPDATED_AT' -%}
            {%- set ns.updated_col = row['RAW_COLUMN_NAME'] -%}
        {%- endif -%}
    {%- endfor -%}

{%- endif -%}

{%- if materialized == 'incremental' -%}
{{ config(
    alias                = ns.alias,
    materialized         = 'incremental',
    unique_key           = unique_key,
    incremental_strategy = incremental_strategy,
    on_schema_change     = on_schema_change
) }}
{%- else -%}
{{ config(alias = ns.alias, materialized = materialized) }}
{%- endif -%}

WITH src AS (

    SELECT *
    FROM {{ source(source_name, raw_table) }}

),

staged AS (

    SELECT

        {%- for row in ns.columns %}
        {%- set raw_col    = row['RAW_COLUMN_NAME'] %}
        {%- set tgt_col    = row['TARGET_COLUMN_NAME'] %}
        {%- set dtype      = row['TARGET_DATA_TYPE'] | upper %}
        {%- if dtype == 'INT' %}
        {{ raw_col }} :: INT                              AS {{ tgt_col }},
        {%- elif dtype == 'BOOLEAN' %}
        {{ raw_col }} :: BOOLEAN                         AS {{ tgt_col }},
        {%- elif dtype == 'TIMESTAMP_NTZ' %}
        TO_TIMESTAMP_NTZ({{ raw_col }} :: NUMBER, 6)     AS {{ tgt_col }},
        {%- else %}
        {{ raw_col }}{% if raw_col != tgt_col %} AS {{ tgt_col }}{% endif %},
        {%- endif %}
        {%- endfor %}

        {{ ns.updated_col }} :: NUMBER                    AS ROW_VALID_FROM,
        LEAD({{ ns.updated_col }} :: NUMBER) OVER (
            PARTITION BY {{ ns.business_key_raw }}
            ORDER BY {{ ns.updated_col }} :: NUMBER
        )                                                 AS _ROW_VALID_TO,

        CURRENT_TIMESTAMP() :: TIMESTAMP_NTZ              AS LOADED_AT,
        '{{ source(source_name, raw_table).identifier }}' AS SOURCE

    FROM src

    {%- if materialized == 'incremental' and is_incremental() %}
    WHERE TO_TIMESTAMP_NTZ({{ ns.updated_col }} :: NUMBER, 6)
              >= (SELECT MAX(UPDATED_AT) FROM {{ this }})
    {%- endif %}

)

SELECT

    {%- for row in ns.columns %}
    {{ row['TARGET_COLUMN_NAME'] }},
    {%- endfor %}
    TO_TIMESTAMP_NTZ(ROW_VALID_FROM, 6)                            AS ROW_VALID_FROM,
    TO_TIMESTAMP_NTZ(COALESCE(_ROW_VALID_TO, 253402214400000000), 6) AS ROW_VALID_TO, -- 9999-12-31 00:00:00 UTC (end-of-time sentinel)
    CASE WHEN _ROW_VALID_TO IS NULL THEN 1 ELSE 0 END               AS ROW_IS_ACTIVE,
    LOADED_AT,
    SOURCE

FROM staged

{% endmacro %}
