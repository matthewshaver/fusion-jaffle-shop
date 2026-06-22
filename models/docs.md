{% docs customer_id %}
The unique surrogate key for each customer record. Derived from the source system's
customer identifier.
{% enddocs %}

{% docs order_id %}
The unique surrogate key for each order. Maps 1:1 to the transaction recorded in the
source system.
{% enddocs %}

{% docs order_total %}
The final amount charged to the customer, including applicable local tax. Expressed in
US dollars (converted from cents in the staging layer).
{% enddocs %}

{% docs ordered_at %}
The timestamp when the order was confirmed by the point-of-sale system, truncated to
day granularity.
{% enddocs %}

{% docs location_id %}
The unique identifier for a Jaffle Shop store location. Foreign key to the locations
mart.
{% enddocs %}

{% docs customer_type %}
Indicates whether this is a first-time or repeat customer at the time of the metric
calculation. Values: `new` (exactly 1 lifetime order) or `returning` (2 or more).
{% enddocs %}

{% docs lifetime_spend %}
Total amount paid by a customer across all orders, inclusive of tax. Expressed in US
dollars.
{% enddocs %}

{% docs product_id %}
The stock-keeping unit (SKU) for a menu item. Follows the format `XXX-NNN` where the
prefix identifies the product category (e.g. `JAF` for jaffles, `BEV` for beverages).
{% enddocs %}

{% docs supply_cost %}
The aggregated cost of all supplies required to produce one unit of a product, expressed
in US dollars (converted from cents in the staging layer).
{% enddocs %}

{% docs is_food_item %}
Boolean flag indicating the product is a food item (jaffle). Derived from the product
type field in the source catalog.
{% enddocs %}

{% docs is_drink_item %}
Boolean flag indicating the product is a beverage. Derived from the product type field
in the source catalog.
{% enddocs %}
