WITH s AS (
    SELECT * FROM {{ source('source', 'manual_rating') }}
)

SELECT
    s.payment_id,
    s.team_id,
    s.review_id,
    s.category_id,
    s.rating,
    s.cause,
    s.rating_max,
    s.weight,
    s.critical,
    s.category_name
FROM s
