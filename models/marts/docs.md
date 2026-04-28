{% docs fct_interviews %}
One row per interview. Combines interview attributes at creation time with
pivoted status timestamps, computed duration metrics, and point-in-time
snapshots of candidate and interviewer attributes.

Each interview is identified by `INTERVIEW_ID`. Status timestamps (e.g. `SCHEDULED_AT`,
`IN_PROGRESS_AT`) are derived by pivoting the SCD2 source — they represent the first time
each status was observed on the interview. Candidate and interviewer attributes are resolved
via a point-in-time join against the SCD2 dimensions using the interview `CREATED_AT`.
{% enddocs %}

{% docs scd2_validity_columns %}
This model uses Slowly Changing Dimension Type 2 (SCD2) to preserve full attribute history.

- `VALID_FROM` — timestamp when this version of the record became active.
- `VALID_TO` — timestamp when this version was superseded. The sentinel value `9999-12-31` indicates the currently active version.
- `ROW_IS_ACTIVE` — `1` for the current active version, `0` for historical versions.

For point-in-time lookups, join on `event_timestamp >= VALID_FROM AND event_timestamp < VALID_TO`.
For current state only, filter on `ROW_IS_ACTIVE = 1`.
{% enddocs %}

{% docs interview_duration_minutes %}
Elapsed minutes between the `IN_PROGRESS` and `PENDING_FEEDBACK` statuses.

Only **online** interviews (`RUN_TYPE = 'ONLINE'`) pass through `IN_PROGRESS`, so this metric
is `NULL` for offline interviews. Computed as:

```
DATEDIFF(minute, IN_PROGRESS_AT, PENDING_FEEDBACK_AT)
```
{% enddocs %}
