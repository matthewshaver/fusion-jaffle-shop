{% test validate_sku(model, column_name) %}

with validation as (

    select
        {{ column_name }} as product_id

    from {{ model }}

),

validation_errors as (

    select
        product_id

    from validation

    where
        NOT REGEXP_LIKE({{ column_name }}, '^[A-Za-z]{3}-[0-9]{3}$')

)

select *
from validation_errors

{% endtest %}
