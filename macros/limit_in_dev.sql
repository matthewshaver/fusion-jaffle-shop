{% macro limit_in_dev(timestamp_column, relation) %}
    {#
      In the dev target, keep only a recent slice of the data to speed up builds.
      The window is anchored to the data's own MAX timestamp (not the wall clock),
      so static/demo datasets never age past the window and silently zero out
      downstream models. Widen the interval below for richer aggregate charts.
    #}
    {% if target.name == 'dev' %}
        and {{ timestamp_column }} > (
            select {{ dbt.dateadd('year', -3, 'max(' ~ timestamp_column ~ ')') }}
            from {{ relation }}
        )
    {% endif %}
{% endmacro %}
