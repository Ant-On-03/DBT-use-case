# Citi Bike dbt Demo Project

This dbt project transforms raw NYC Citi Bike trip and station data into a clean, analytics-ready dimensional model. The pipeline extracts raw data from Google BigQuery's public datasets and applies modular transformations, data quality testing, and advanced materialization strategies to produce robust fact and dimension tables. 

## Project Architecture

The project follows a standard multi-layer architecture to organize models from raw data ingestion to business-ready reporting tables.

*   **0_raw:** Defines the connection to the source database (`bigquery-public-data.new_york_citibike`), establishing source configurations for the `citibike_stations` (raw station metadata) and `citibike_trips` (historical trip records) tables.
*   **1_staging:** The entry point for raw data, focusing on renaming, casting, and basic filtering. 
    *   `stg_bigquery-public-data_citibike__stations.sql`: Cleans metadata and locations, removing records with null station IDs.
    *   `stg_bigquery-public-data_citibike__trips.sql`: Filters out invalid rides (requiring `trip_duration_seconds > 0`) and generates a robust surrogate primary key (`trip_id`) by hashing the `bikeid`, `starttime`, `start_station_id`, and `stoptime`.
*   **2_intermediate:** Houses models that perform complex business logic and calculations before joining them into final marts.
    *   `int_citibike__trips_enriched.sql`: Enriches trip data by calculating `rider_age_at_trip` from the rider's birth year, and utilizes BigQuery spatial functions (`ST_GEOGPOINT` and `ST_DISTANCE`) to calculate the straight-line `trip_distance_meters` between start and end stations.
*   **3_marts:** The final presentation layer designed for BI tools and downstream analysts.
    *   `dim_stations.sql`: A Type 1 Dimension table containing all unique Citi Bike stations.
    *   `fct_trips.sql`: The core Fact table containing individual trips. 

## Key Technical Implementations

*   **Incremental Loading:** The `fct_trips` model is materialized as an `incremental` table, processing only new records based on the `started_at` timestamp for optimized BigQuery compute costs.
*   **Table Partitioning & Clustering:** `fct_trips` is partitioned by day on the `started_at` field and clustered by `start_station_id`, `end_station_id`, and `rider_type` to optimize query performance.
*   **Geospatial Processing:** Translates raw latitude and longitude coordinates into enriched physical distance metrics natively within the transformation layer.

## Data Quality & Testing

Comprehensive tests are defined across `.yml` files in the project to ensure data integrity:

*   **Primary/Foreign Keys:** `unique` and `not_null` constraints on primary keys like `station_id` and `trip_id`.
*   **Referential Integrity:** `relationships` tests enforce that `start_station_id` and `end_station_id` in the trips models map strictly to valid stations in the station models.
*   **Accepted Values:** Enforces that `rider_type` strictly contains valid categories ('Subscriber' or 'Customer').
*   **Valid Ranges:** Uses the `accepted_range` test (min 16, max 100) on the calculated `rider_age_at_trip` field to prevent invalid data or time-traveler anomalies.

## Execution Guide

To run and test this project in your local environment, use the standard dbt command workflow:

1.  **Install Dependencies:** `dbt deps` (Installs required packages like `dbt_utils` for surrogate key generation)
2.  **Build Models:** `dbt run` (Use `dbt run --full-refresh` on the first run to build the incremental models from scratch)
3.  **Run Tests:** `dbt test`
4.  **Generate Documentation:** `dbt docs generate` followed by `dbt docs serve`
