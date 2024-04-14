WITH s AS (
    SELECT * FROM {{ source('source', 'manual_reviews') }}
)

SELECT
    review_id,
    payment_id,
    payment_token_id,
    created AS created_at,
    conversation_created_date,
    conversation_external_id AS external_ticket_id,
    team_id,
    reviewer_id,
    reviewee_id,
    comment_id,
    scorecard_id,
    scorecard_tag,
    score,
    updated_at,
    updated_by,
    assignment_review,
    seen,
    disputed,
    review_time_seconds,
    assignment_name,
    imported_at
FROM s
