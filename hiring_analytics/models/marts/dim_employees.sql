{{ config(materialized='table') }}

SELECT
    EMPLOYEE_ID,
    JOB_FUNCTION_ID,
    PRIMARY_SKILL_ID,
    PRODUCTION_CATEGORY,
    EMPLOYMENT_STATUS,
    ORG_CATEGORY,
    ORG_CATEGORY_TYPE,
    WORK_START_AT,
    WORK_END_AT,
    IS_ACTIVE,
    CREATED_AT,
    UPDATED_AT,
    ROW_VALID_FROM                       AS VALID_FROM,
    ROW_VALID_TO                         AS VALID_TO,
    ROW_IS_ACTIVE

FROM {{ ref('stg_raw__employees') }}
