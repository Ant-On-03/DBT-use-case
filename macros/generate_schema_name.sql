{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if target.name == 'dev' -%}
        {# En desarrollo: ignora los esquemas personalizados y manda todo a tu dataset personal #}
        {{ default_schema }}

    {%- elif custom_schema_name is none -%}
        {# Si no hay esquema personalizado definido, usa el del profile #}
        {{ default_schema }}

    {%- else -%}
        {# En producción/CI: concatena el target con el esquema personalizado #}
        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}