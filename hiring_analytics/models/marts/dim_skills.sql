{{ config(materialized='table') }}

SELECT
    SKILL_ID,
    IS_ACTIVE,
    IS_PRIMARY,
    IS_KEY,
    IS_KEY_REASON,
    TYPE,
    NAME,
    URL,
    PARENT_ID,
    UPDATED_AT

FROM {{ ref('stg_raw__latest_skills') }}
