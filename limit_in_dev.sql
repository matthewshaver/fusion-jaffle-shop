{% macro limit_in_dev(timestamp_column) %}
    {% if target.name == 'dev' %}
        AND {{ timestamp_column }} > current_timestamp() - interval '1 year'
        AND {{ timestamp_column }} <= current_timestamp()
    {% endif %}
{% endmacro %}