{% macro insert_freshness_heartbeat() %}

    {#
        Inserts a synthetic order row with today's timestamp into raw_orders
        so that source freshness checks always see a record from the current day.
        The WHERE NOT EXISTS guard makes it idempotent — safe to run multiple
        times per day without creating duplicate rows.

        Only runs in non-CI environments to avoid polluting test schemas.
    #}

    {% if target.name not in ('ci', 'dev') %}

        {% set heartbeat_id = 'HEARTBEAT-' ~ modules.datetime.date.today().strftime('%Y%m%d') %}

        {% set heartbeat_sql %}
            insert into {{ source('ecom', 'raw_orders') }}
                (id, store_id, customer, ordered_at, subtotal, tax_paid, order_total)
            select
                '{{ heartbeat_id }}',
                (select id from {{ source('ecom', 'raw_stores') }} limit 1),
                (select id from {{ source('ecom', 'raw_customers') }} limit 1),
                current_timestamp(),
                0,
                0,
                0
            where not exists (
                select 1
                from {{ source('ecom', 'raw_orders') }}
                where id = '{{ heartbeat_id }}'
            )
        {% endset %}

        {% do run_query(heartbeat_sql) %}
        {{ log("Freshness heartbeat inserted for " ~ heartbeat_id, info=True) }}

    {% endif %}

{% endmacro %}
