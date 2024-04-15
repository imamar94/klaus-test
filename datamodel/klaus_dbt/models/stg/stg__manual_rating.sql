WITH s AS (
    SELECT * FROM {{ source('source', 'manual_rating') }}
)

SELECT
    s.payment_id,
    s.team_id,
    s.review_id,
    s.category_id,
    CASE WHEN s.rating = 42 THEN NULL ELSE s.rating END AS rating,
    s.cause,
    s.rating_max,
    s.weight,
    s.critical,
    s.category_name
FROM s
