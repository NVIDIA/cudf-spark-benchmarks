
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_id
),
SalesByRegion AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_sales_quantity) AS region_sales_quantity,
        SUM(cs.total_sales_value) AS region_sales_value,
        AVG(cs.total_orders) AS avg_orders_per_customer
    FROM CustomerSales cs
    JOIN customer_address ca ON cs.c_customer_id = ca.ca_address_id
    GROUP BY ca.ca_state
),
WeeklySales AS (
    SELECT 
        d.d_week_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS weekly_sales_value
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_week_seq
)
SELECT 
    sr.ca_state,
    sr.region_sales_quantity,
    sr.region_sales_value,
    sr.avg_orders_per_customer,
    ws.weekly_sales_value
FROM SalesByRegion sr
JOIN WeeklySales ws ON sr.region_sales_value > 10000
ORDER BY sr.region_sales_value DESC, ws.weekly_sales_value DESC
LIMIT 10;
