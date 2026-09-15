{{ 
    config(
        materialization='table',
        description='Type 1 Dimension table containing all Citi Bike stations.'
    ) 
}}

with 

staging_stations as (
    select * from {{ ref('stg_bigquery-public-data_citibike__stations') }}
),

final as (
    select
        station_id,
        station_name,
        station_lat,
        station_lon
        -- If you had neighborhood or borough mapping, it would be joined in here.
    from staging_stations
    -- Optional: If your source has duplicate station IDs over time, 
    -- you can enforce uniqueness here to make it a true Type 1 dimension.
    qualify row_number() over (partition by station_id order by station_name) = 1
)

select * from final