WITH source AS (
    SELECT * FROM {{ ref('stg__manual_reviews') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['r_manual.review_id', "'manual'"]) }} AS review_key
    review_id,
    payment_id,
    payment_token_id,
    created AS created_at,
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
FROM source
