{{
    config(
        materialized='incremental',
        unique_key='event_key'
    )
}}

WITH filter_id AS (
SELECT 
	user_id,
	product_id,
	event_timestamp,
	event_type,
	price_usd,
	user_session
FROM {{ source('staging', 'stg_table') }} a
WHERE EXISTS(
	SELECT 1 FROM {{ ref('dim_users') }} b WHERE a.user_id = b.user_id
) AND EXISTS(
	SELECT 1 FROM {{ ref('dim_products') }} b WHERE a.product_id = b.product_id
)
{% if is_incremental() %}
    AND event_timestamp >= (SELECT MAX(event_timestamp) FROM {{ this }})
{% endif %}


), 

final AS (
SELECT 
	md5(
    COALESCE(user_id::text, '') || '|' ||
    COALESCE(product_id::text, '') || '|' ||
    COALESCE(event_timestamp::text, '') || '|' ||
    COALESCE(event_type, '') || '|' ||
    COALESCE(user_session, '')
	) AS event_key,
	user_id,
	product_id,
	event_timestamp,
	event_type,
	price_usd,
	user_session,
	event_timestamp::date AS event_date,
	EXTRACT(HOUR FROM event_timestamp)::int AS event_hour
FROM filter_id 

)

SELECT 
	DISTINCT ON (event_key) 
	event_key,
	user_id,
	product_id,
	event_timestamp,
	event_type,
	price_usd,
	user_session,
	event_date,
	event_hour
FROM final
ORDER BY event_key, price_usd DESC NULLS LAST