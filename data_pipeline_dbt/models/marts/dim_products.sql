{{
    config(
        materialized='incremental',
        unique_key='product_id'
    )
}}

WITH batch AS (
    SELECT
        product_id,
        event_timestamp,
        category_id,
        brand,
        price_usd
    FROM {{ source('staging', 'stg_table') }}
    WHERE product_id IS NOT NULL

    {% if is_incremental() %}
      AND event_timestamp > (SELECT MAX(last_seen_at) FROM {{ this }})
    {% endif %}
),

seen AS (
    SELECT
        product_id,
        MIN(event_timestamp) AS first_ts,
        MAX(event_timestamp) AS last_ts
    FROM batch
    GROUP BY product_id
),

latest_brand AS (
    SELECT DISTINCT ON (product_id) product_id, brand
    FROM batch
    WHERE brand IS NOT NULL
    ORDER BY product_id, event_timestamp DESC
),

latest_category AS (
    SELECT DISTINCT ON (product_id) product_id, category_id
    FROM batch
    WHERE category_id IS NOT NULL
    ORDER BY product_id, event_timestamp DESC
),

latest_price AS (
    SELECT DISTINCT ON (product_id) product_id, price_usd
    FROM batch
    WHERE price_usd IS NOT NULL
    ORDER BY product_id, event_timestamp DESC
),

first_price AS (
    SELECT DISTINCT ON (product_id) product_id, price_usd
    FROM batch
    WHERE price_usd IS NOT NULL
    ORDER BY product_id, event_timestamp ASC
)

SELECT
    s.product_id,

    {% if is_incremental() %}
    COALESCE(lb.brand, NULLIF(t.brand, 'Unknown'), 'Unknown') AS brand,
    COALESCE(lc.category_id, t.category_id)                   AS category_id,
    COALESCE(lp.price_usd, t.current_price)                   AS current_price,
    COALESCE(t.initial_price, fp.price_usd)                   AS initial_price,
    COALESCE(t.first_seen_at, s.first_ts)                     AS first_seen_at,
    {% else %}
    COALESCE(lb.brand, 'Unknown')                             AS brand,
    lc.category_id                                            AS category_id,
    lp.price_usd                                              AS current_price,
    fp.price_usd                                              AS initial_price,
    s.first_ts                                                AS first_seen_at,
    {% endif %}

    s.last_ts AS last_seen_at

FROM seen s
LEFT JOIN latest_brand    lb ON lb.product_id = s.product_id
LEFT JOIN latest_category lc ON lc.product_id = s.product_id
LEFT JOIN latest_price    lp ON lp.product_id = s.product_id
LEFT JOIN first_price     fp ON fp.product_id = s.product_id

{% if is_incremental() %}
LEFT JOIN {{ this }} t ON t.product_id = s.product_id
{% endif %}