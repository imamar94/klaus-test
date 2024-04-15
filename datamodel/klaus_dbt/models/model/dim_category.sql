WITH category_autoqa AS (
    SELECT
        category_id
        , MAX(category_name) AS category_name
    FROM {{ ref('stg__autoqa_ratings') }}
    GROUP BY 1
),

category_manual AS (
    SELECT
        category_id
        , MAX(category_name) AS category_name
        , MAX(weight) AS category_weight
    FROM {{ ref('stg__manual_rating') }}
    GROUP BY 1
)

SELECT
    COALESCE(a.category_id, b.category_id) AS category_id
    , COALESCE(a.category_name, b.category_name) AS category_name
    , COALESCE(category_weight,1) AS category_weight
FROM category_autoqa a
FULL JOIN category_manual b
    USING (category_id)
