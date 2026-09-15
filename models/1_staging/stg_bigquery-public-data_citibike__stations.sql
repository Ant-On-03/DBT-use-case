{{ 
    config(
        materialization='view',
        description='Staging model for Citi Bike stations. Cleans metadata and locations.'
    ) 
}}

with 

source as (
    select * from {{ source('bigquery-public-data_citibike', 'citibike_stations') }}
),

renamed_and_casted as (
    select
        -- Primary Key
        cast(station_id as string) as station_id,

        -- Station Attributes
        cast(name as string) as station_name,
        cast(short_name as string) as station_short_name,
        
        -- Geospatial
        cast(latitude as float64) as station_lat,
        cast(longitude as float64) as station_lon,
        
        -- Capacity metrics
        cast(capacity as int64) as total_capacity,
        cast(region_id as string) as region_id

        -- Note: We intentionally drop real-time columns like 'num_bikes_available' 
        -- here because staging should focus on historical dimension attributes, 
        -- not volatile real-time API states unless building a real-time fact table.
        
    from source
),

filtered as (
    select *
    from renamed_and_casted
    where station_id is not null
)

select * from filtered