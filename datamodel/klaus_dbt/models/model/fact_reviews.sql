WITH r_auto AS (
    SELECT * FROM {{ ref('stg__autoqa_reviews') }}
),

r_manual AS (
    SELECT * FROM {{ ref('stg__manual_reviews') }}
),

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['r_auto.autoqa_review_id', "'autoqa'"]) }} AS review_key
    , 'autoqa' AS review_source
    , r_auto.autoqa_review_id AS source_review_id
    , external_ticket_id
    , created_at
    , team_id
    , reviewee_id
    , updated_at
FROM r_auto

UNION ALL

SELECT
    {{ dbt_utils.generate_surrogate_key(
        ['r_manual.review_id', "'manual'"]) }} AS review_key
    , 'manual' AS review_source
    , r_manual.review_id AS source_review_id
    , external_ticket_id
    , created_at
    , team_id
    , reviewee_id
    , updated_at
FROM r_manual
