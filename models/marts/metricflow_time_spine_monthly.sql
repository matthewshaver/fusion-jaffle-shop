{{
    config(
        materialized='table'
    )
}}

with daily_spine as (

    select date_day from {{ ref('metricflow_time_spine') }}

),

monthly as (

    select distinct
        {{ dbt.date_trunc('month', 'date_day') }} as date_month

    from daily_spine

)

select * from monthly
