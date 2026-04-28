{{ config(materialized='table') }}

SELECT
    JOB_FUNCTION_ID,
    BASE_NAME,
    CATEGORY,
    IS_ACTIVE,
    LEVEL,
    TRACK,
    SENIORITY_LEVEL,
    SENIORITY_INDEX,
    UPDATED_AT

FROM {{ ref('stg_raw__latest_job_functions') }}
