
WITH CustomerLocation AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(c_customer_sk) AS customer_count
    FROM
        customer_address
    JOIN customer ON customer.c_current_addr_sk = ca_address_sk
    GROUP BY
        ca_city, ca_state
),
ItemSales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id
),
SalesAnalysis AS (
    SELECT
        cl.ca_city,
        cl.ca_state,
        it.i_item_id,
        it.total_quantity_sold,
        it.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cl.ca_city, cl.ca_state ORDER BY it.total_quantity_sold DESC) AS rank
    FROM
        CustomerLocation cl
    JOIN ItemSales it ON cl.customer_count > 100
)
SELECT
    ca_city,
    ca_state,
    i_item_id,
    total_quantity_sold,
    total_orders
FROM
    SalesAnalysis
WHERE
    rank <= 5
ORDER BY
    ca_state, ca_city, total_quantity_sold DESC;
