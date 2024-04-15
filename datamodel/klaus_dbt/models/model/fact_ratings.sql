WITH r_auto AS (
    SELECT * FROM {{ ref('stg__autoqa_ratings') }}
),

r_manual AS (
    SELECT * FROM {{ ref('stg__manual_rating') }}
)

(
    SELECT
        {{ dbt_utils.generate_surrogate_key(
            ['r_auto.autoqa_rating_id', "'autoqa'"]) }} AS rating_key
        , {{ dbt_utils.generate_surrogate_key(
            ['autoqa_review_id', "'autoqa'"]) }} AS review_key
        , 'autoqa' AS rating_source
        , r_auto.autoqa_review_id AS source_review_id
        , payment_id
        , team_id
        , category_id
        , rating_scale_score
        , CAST(score * rating_scale_score / 100 AS INT) as rating
        , score
        , NULL as cause
    FROM r_auto
)

UNION ALL

(
    SELECT
        {{ dbt_utils.generate_surrogate_key(
            ['review_id', 'category_id', "'manual'"]) }} AS rating_key
        , {{ dbt_utils.generate_surrogate_key(
            ['cast(review_id as string)', "'manual'"]) }} AS review_key
        , 'manual' AS rating_source
        , CAST(r_manual.review_id AS STRING) AS source_review_id
        , payment_id
        , team_id
        , category_id
        , rating_max AS rating_scale_score
        , rating
        , rating * 100.0 / rating_max score
        , cause
    FROM r_manual
)
