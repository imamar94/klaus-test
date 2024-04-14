WITH s AS (
    SELECT * FROM {{ source('source', 'autoqa_ratings') }}
)

SELECT
    s.autoqa_review_id
    , s.autoqa_rating_id
    , s.payment_id
    , s.team_id
    , s.payment_token_id
    , s.external_ticket_id
    , s.rating_category_id
    , s.rating_category_name
    , s.rating_scale_score
    , s.score
    , s.reviewee_internal_id
FROM s
