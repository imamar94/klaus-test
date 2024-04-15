WITH source AS (
    SELECT * FROM {{ ref('stg__autoqa_root_cause') }}
)

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(
        ['autoqa_rating_id', "root_cause"]) }} AS autoqa_rootcause_key
    , {{ dbt_utils.generate_surrogate_key(
        ['autoqa_rating_id', "'autoqa'"]) }} AS rating_key
    , root_cause
FROM source
