{{ config(
    materialized='incremental',
    unique_key='event_timestamp'
) }}


SELECT 
    event_time::TIMESTAMP AS event_timestamp,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    user_id,
    user_session,
    CAST(price AS DECIMAL(10,2)) AS price_usd
FROM {{ source('raw', 'raw_data') }}
WHERE price IS NOT NULL
  AND (user_id IS NOT NULL OR event_type = 'purchase')

{% if is_incremental() %}
    AND event_time::TIMESTAMP > (SELECT MAX(event_timestamp) FROM {{ this }})
{% endif %}
    