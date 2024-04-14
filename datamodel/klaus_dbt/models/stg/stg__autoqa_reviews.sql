WITH s AS (
    SELECT * FROM {{ source('source', 'autoqa_reviews') }}
)

SELECT
    s.autoqa_review_id,
    s.payment_id,
    s.payment_token_id,
    s.external_ticket_id,
    s.created_at,
    s.conversation_created_at,
    s.conversation_created_date,
    s.team_id,
    s.reviewee_internal_id AS reviewee_id,
    s.updated_at
FROM s
