{{
    config(
        materialized='incremental',
        unique_key='user_id'
    )
}}
WITH users AS (
SELECT 
	user_id,
	MIN(event_timestamp) as first_seen_at,
	MAX(event_timestamp) as last_seen_at,
	MIN(event_timestamp) FILTER(WHERE event_type = 'purchase') as first_purchase_at
FROM {{ source('staging', 'stg_table') }}
WHERE user_id IS NOT NULL

  {% if is_incremental() %}
      AND event_timestamp > (SELECT MAX(last_seen_at) FROM {{ this }})
    {% endif %}
    
GROUP BY user_id
),
    final AS (

SELECT
    a.user_id,
    {% if is_incremental() %}
        COALESCE(b.first_seen_at, a.first_seen_at) as first_seen_at,
        a.last_seen_at,
        COALESCE(b.first_purchase_at, a.first_purchase_at) as first_purchase_at
    {% else %}
        a.first_seen_at,
        a.last_seen_at,
        a.first_purchase_at
    {% endif %}
FROM users a

    {% if is_incremental() %}
LEFT JOIN {{ this }} b ON a.user_id = b.user_id
    {% endif %}
)
SELECT 
    *,
    first_purchase_at IS NOT NULL AS is_buyer
FROM final



  

