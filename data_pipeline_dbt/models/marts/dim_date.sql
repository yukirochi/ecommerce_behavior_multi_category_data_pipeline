{{ config(materialized='table') }}

WITH range_date AS (
    SELECT
        MIN(event_timestamp)::DATE as start_date,
        MAX(event_timestamp)::DATE current_date
    FROM {{ source('staging', 'stg_table') }}
),
days AS (
    SELECT
        GENERATE_SERIES(start_date, current_date, INTERVAL '1 day')::DATE as full_date
    FROM range_date
)
SELECT 
	TO_CHAR(full_date, 'YYYYMMDD') as date_key,
	full_date,
	EXTRACT(YEAR FROM full_date)::INT as year,
	EXTRACT(QUARTER FROM full_date)::INT as quarter,
	EXTRACT(MONTH FROM full_date)::INT as month,
	TO_CHAR(full_date, 'FMMonth') as month_name,
	EXTRACT(DAY FROM full_date)::INT as day,
	EXTRACT(ISODOW FROM full_date)::INT as day_of_week,
	TO_CHAR(full_date, 'FMDay') as day_name,
	EXTRACT(WEEK FROM full_date)::INT as week_of_year,
	EXTRACT(ISODOW FROM full_date) IN (6,7) as is_weekend
FROM days