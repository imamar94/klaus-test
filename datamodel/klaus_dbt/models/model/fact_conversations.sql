WITH s AS (
    SELECT 
        * 
        , ROW_NUMBER() OVER (PARTITION BY external_ticket_id ORDER BY imported_at DESC) AS rn
    FROM {{ ref('stg__conversations') }}
)

SELECT DISTINCT
    s.external_ticket_id
    , s.conversation_created_at
    , s.conversation_created_at_date
    , s.channel
    , s.assignee_id
    , s.updated_at
    , s.closed_at
    , s.message_count
    , s.last_reply_at
    , s.language
    , s.imported_at
    , s.unique_public_agent_count
    , s.public_mean_character_count
    , s.public_mean_word_count
    , s.private_message_count
    , s.public_message_count
    , s.klaus_sentiment
    , s.is_closed
    , s.agent_most_public_messages
    , s.first_response_time
    , s.first_resolution_time_seconds
    , s.full_resolution_time_seconds
    , s.most_active_internal_user_id
    , s.deleted_at
FROM s
WHERE rn = 1
