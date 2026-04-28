{{ config(materialized='table') }}

SELECT
    CANDIDATE_ID,
    PRIMARY_SKILL_ID,
    STAFFING_STATUS,
    ENGLISH_LEVEL,
    JOB_FUNCTION_ID,
    CREATED_AT,
    UPDATED_AT,
    ROW_VALID_FROM                       AS VALID_FROM,
    ROW_VALID_TO                         AS VALID_TO,
    ROW_IS_ACTIVE

FROM {{ ref('stg_raw__candidates') }}
