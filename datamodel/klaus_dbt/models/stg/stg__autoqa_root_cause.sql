WITH s AS (
    SELECT * FROM {{ source('source', 'autoqa_root_cause') }}
)

SELECT
    s.autoqa_rating_id
    , s.category
    , s.count
    , s.root_cause
FROM s
