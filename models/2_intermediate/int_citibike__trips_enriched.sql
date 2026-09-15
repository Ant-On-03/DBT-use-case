{{ 
    config(
        materialization='view',
        description='Enriches trip data with calculated fields like rider age and spatial distance.'
    ) 
}}

with 

trips as (
    select * from {{ ref('stg_bigquery-public-data_citibike__trips') }}
),

enriched as (
    select
        -- Keep all existing staging columns
        *,

        -- 1. Rider Age Calculation
        -- Subtract the birth year from the year the trip actually occurred
        case 
            when rider_birth_year is not null 
            then extract(year from started_at) - rider_birth_year
            else null
        end as rider_age_at_trip,

        -- 2. Spatial Distance Calculation (Straight line in meters)
        -- BigQuery ST_GEOGPOINT requires (longitude, latitude) in that exact order
        case
            when start_station_lon is not null 
             and start_station_lat is not null
             and end_station_lon is not null 
             and end_station_lat is not null
            then st_distance(
                st_geogpoint(start_station_lon, start_station_lat),
                st_geogpoint(end_station_lon, end_station_lat)
            )
            else null
        end as trip_distance_meters

    from trips
)

select * from enriched