{{ config(severity='error') }}

SELECT 'stg_raw__interviews' AS model, ID AS row_key
FROM {{ ref('stg_raw__interviews') }}
WHERE ROW_VALID_FROM > ROW_VALID_TO

UNION ALL

SELECT 'stg_raw__candidates', CANDIDATE_ID
FROM {{ ref('stg_raw__candidates') }}
WHERE ROW_VALID_FROM > ROW_VALID_TO

UNION ALL

SELECT 'stg_raw__employees', EMPLOYEE_ID
FROM {{ ref('stg_raw__employees') }}
WHERE ROW_VALID_FROM > ROW_VALID_TO

UNION ALL

SELECT 'stg_raw__job_functions', JOB_FUNCTION_ID
FROM {{ ref('stg_raw__job_functions') }}
WHERE ROW_VALID_FROM > ROW_VALID_TO

UNION ALL

SELECT 'stg_raw__skills', SKILL_ID
FROM {{ ref('stg_raw__skills') }}
WHERE ROW_VALID_FROM > ROW_VALID_TO
