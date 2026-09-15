{{ 
    config(
        materialization='incremental',
        unique_key='trip_id',
        partition_by={
            "field": "started_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by=["start_station_id", "end_station_id", "rider_type"],
        description='Core Fact table containing individual Citi Bike trips.'
    ) 
}}

with 

enriched_trips as (
    select * from {{ ref('int_citibike__trips_enriched') }}
),

final as (
    select
        -- Primary Key
        trip_id,

        -- Timestamps
        started_at,
        ended_at,

        -- Foreign Keys
        start_station_id,
        end_station_id,

        -- Facts / Measures
        trip_duration_seconds,
        trip_distance_meters,

        -- Degenerate Dimensions (Profiles)
        bike_id,
        rider_type,
        rider_birth_year,
        rider_gender,
        rider_age_at_trip

    from enriched_trips

    -- =========================================================
    -- INCREMENTAL LOGIC
    -- =========================================================
    {% if is_incremental() %}
    
        -- This tells dbt: "If this table already exists in BigQuery, 
        -- only process records that are newer than the most recent 
        -- timestamp we currently have in the table."
        where started_at > (select max(started_at) from {{ this }})
        
    {% endif %}
)

select * from final