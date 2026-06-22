{% test validate_sku(model, column_name) %}

with validation as (

    select
        {{ column_name }} as sku_value

    from {{ model }}

),

validation_errors as (

    select
        sku_value

    from validation

    where
        not regexp_like(sku_value, '^[A-Za-z]{3}-[0-9]{3}$')

)

select *
from validation_errors

{% endtest %}
