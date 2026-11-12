{{
    config(
        materialized='table'
    )
}}


SELECT
	category_id,
	MAX(category_code),
	SPLIT_PART(MAX(category_code),'.',1) AS category_1,
	COALESCE(SPLIT_PART(MAX(category_code),'.',2), null) AS category_2,
	COALESCE(SPLIT_PART(MAX(category_code),'.',3), null) AS category_3
FROM {{ source('staging', 'stg_table') }}
WHERE category_code IS NOT NULL AND category_id IS NOT NULL
GROUP BY category_id