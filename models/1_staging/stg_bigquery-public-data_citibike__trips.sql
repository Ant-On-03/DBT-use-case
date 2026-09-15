{{ 
    config(
        materialization='view',
        description='Staging model for Citi Bike trips. Cleans types and removes invalid rides.'
    ) 
}}

with 

source as (
    select * from {{ source('bigquery-public-data_citibike', 'citibike_trips') }}
),

renamed_and_casted as (
    select
        -- Primary Key Generation: Hashing unique composite fields
        {{ dbt_utils.generate_surrogate_key([
            'bikeid', 
            'starttime', 
            'start_station_id',
            'stoptime'
        ]) }} as trip_id,

        -- Timestamps
        cast(starttime as timestamp) as started_at,
        cast(stoptime as timestamp) as ended_at,

        -- Trip Metrics
        cast(tripduration as int64) as trip_duration_seconds,

        -- Foreign Keys & Station Info
        -- Null handling: Coalescing string 'NULL' or empty values to actual SQL nulls if needed
        cast(start_station_id as string) as start_station_id,
        cast(start_station_name as string) as start_station_name,
        cast(start_station_latitude as float64) as start_station_lat,
        cast(start_station_longitude as float64) as start_station_lon,
        
        cast(end_station_id as string) as end_station_id,
        cast(end_station_name as string) as end_station_name,
        cast(end_station_latitude as float64) as end_station_lat,
        cast(end_station_longitude as float64) as end_station_lon,

        -- Rider Profile Attributes
        cast(bikeid as string) as bike_id,
        cast(usertype as string) as rider_type, -- e.g., 'Subscriber' or 'Customer'
        cast(birth_year as int64) as rider_birth_year,
        cast(gender as string) as rider_gender
        
    from source
),

filtered as (
    select *
    from renamed_and_casted
    -- Data Quality Rules: Remove systemic errors from the raw data
    where trip_duration_seconds > 0
      and started_at is not null
      and start_station_id is not null
)

select * from filtered