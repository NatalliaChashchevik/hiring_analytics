{% macro latest_staging_model(staging_model_ref) %}

{%- set raw_table = staging_model_ref | replace('stg_raw__', '') | upper -%}

{%- set _cfg_ref = ref('configuration') -%}

{%- set ns = namespace(
    alias   = staging_model_ref | replace('stg_raw__', 'stg_') ~ '_latest',
    columns = []
) -%}

{%- if execute -%}

    {%- set _cfg_query -%}
        SELECT
            TARGET_TABLE_NAME,
            TARGET_COLUMN_NAME
        FROM {{ _cfg_ref }}
        WHERE UPPER(RAW_TABLE_NAME) = UPPER('{{ raw_table }}')
          AND RAW_COLUMN_NAME IS NOT NULL
          AND TRIM(RAW_COLUMN_NAME) <> ''
        ORDER BY TARGET_ORDER_NUM ASC
    {%- endset -%}

    {%- set _result = run_query(_cfg_query) -%}
    {%- set ns.columns = _result.rows -%}

    {%- if ns.columns | length > 0 -%}
        {%- set ns.alias = ns.columns[0]['TARGET_TABLE_NAME'] | lower ~ '_latest' -%}
    {%- endif -%}

{%- endif -%}

{{ config(alias = ns.alias, materialized = 'view') }}

SELECT *
FROM {{ ref(staging_model_ref) }}
WHERE ROW_IS_ACTIVE = 1

{% endmacro %}
