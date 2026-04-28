SELECT
    INTERVIEW_ID,
    COUNT(*) AS active_row_count
FROM {{ ref('stg_raw__interviews') }}
WHERE ROW_IS_ACTIVE = 1
GROUP BY INTERVIEW_ID
HAVING COUNT(*) <> 1
