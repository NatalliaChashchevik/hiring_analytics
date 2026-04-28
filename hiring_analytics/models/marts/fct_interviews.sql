{{ config(materialized='table') }}

WITH base AS (

    -- One row per interview: attributes at the moment of creation (earliest record)
    SELECT
        INTERVIEW_ID,
        CANDIDATE_TYPE,
        CANDIDATE_ID,
        INTERVIEWER_ID,
        LOCATION,
        LOGGED,
        MEDIA_AVAILABLE,
        RUN_TYPE,
        TYPE,
        CREATED_AT

    FROM {{ ref('stg_raw__interviews') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY INTERVIEW_ID
        ORDER BY ROW_VALID_FROM ASC
    ) = 1

),

status_times AS (

    -- Pivot: first timestamp per status per interview
    SELECT
        INTERVIEW_ID,
        MIN(CASE WHEN STATUS = 'SCHEDULED'         THEN UPDATED_AT END) AS SCHEDULED_AT,
        MIN(CASE WHEN STATUS = 'IN_PROGRESS'       THEN UPDATED_AT END) AS IN_PROGRESS_AT,
        MIN(CASE WHEN STATUS = 'PENDING_FEEDBACK'  THEN UPDATED_AT END) AS PENDING_FEEDBACK_AT,
        MIN(CASE WHEN STATUS = 'COMPLETED'         THEN UPDATED_AT END) AS COMPLETED_AT,
        MIN(CASE WHEN STATUS = 'PASSED'            THEN UPDATED_AT END) AS PASSED_AT,
        MIN(CASE WHEN STATUS = 'FAILED'            THEN UPDATED_AT END) AS FAILED_AT,
        MIN(CASE WHEN STATUS = 'CANCELLED'         THEN UPDATED_AT END) AS CANCELLED_AT

    FROM {{ ref('stg_raw__interviews') }}
    GROUP BY 1

)

SELECT

    b.INTERVIEW_ID,
    b.CANDIDATE_TYPE,
    b.CANDIDATE_ID,
    b.INTERVIEWER_ID,
    b.LOCATION,
    b.LOGGED,
    b.MEDIA_AVAILABLE,
    b.RUN_TYPE,
    b.TYPE,
    b.CREATED_AT,

    -- Status timestamps
    t.SCHEDULED_AT,
    t.IN_PROGRESS_AT,
    t.PENDING_FEEDBACK_AT,
    t.COMPLETED_AT,
    t.PASSED_AT,
    t.FAILED_AT,
    t.CANCELLED_AT,

    -- interview_duration: only online interviews have IN_PROGRESS status
    -- elapsed time from IN_PROGRESS to PENDING_FEEDBACK
    CASE
        WHEN t.IN_PROGRESS_AT IS NOT NULL AND t.PENDING_FEEDBACK_AT IS NOT NULL
        THEN DATEDIFF('minute', t.IN_PROGRESS_AT, t.PENDING_FEEDBACK_AT)
    END AS INTERVIEW_DURATION_MINUTES,

    -- feedback_delay: elapsed time from PENDING_FEEDBACK to COMPLETED
    CASE
        WHEN t.PENDING_FEEDBACK_AT IS NOT NULL AND t.COMPLETED_AT IS NOT NULL
        THEN DATEDIFF('minute', t.PENDING_FEEDBACK_AT, t.COMPLETED_AT)
    END AS FEEDBACK_DELAY_MINUTES,

    -- Candidate attributes at interview creation time (PIT join)
    c.STAFFING_STATUS      AS CANDIDATE_STAFFING_STATUS,
    c.ENGLISH_LEVEL        AS CANDIDATE_ENGLISH_LEVEL,
    c.JOB_FUNCTION_ID      AS CANDIDATE_JOB_FUNCTION_ID,
    c.PRIMARY_SKILL_ID     AS CANDIDATE_PRIMARY_SKILL_ID,

    -- Interviewer attributes at interview creation time (PIT join)
    e.PRODUCTION_CATEGORY  AS INTERVIEWER_PRODUCTION_CATEGORY,
    e.ORG_CATEGORY         AS INTERVIEWER_ORG_CATEGORY,
    e.ORG_CATEGORY_TYPE    AS INTERVIEWER_ORG_CATEGORY_TYPE,
    e.JOB_FUNCTION_ID      AS INTERVIEWER_JOB_FUNCTION_ID,
    e.PRIMARY_SKILL_ID     AS INTERVIEWER_PRIMARY_SKILL_ID

FROM base b

LEFT JOIN status_times t
    ON t.INTERVIEW_ID = b.INTERVIEW_ID

LEFT JOIN {{ ref('dim_candidates') }} c
    ON  c.CANDIDATE_ID = b.CANDIDATE_ID
    AND b.CREATED_AT >= c.VALID_FROM
    AND b.CREATED_AT <  c.VALID_TO

LEFT JOIN {{ ref('dim_employees') }} e
    ON  e.EMPLOYEE_ID = b.INTERVIEWER_ID
    AND b.CREATED_AT >= e.VALID_FROM
    AND b.CREATED_AT <  e.VALID_TO
