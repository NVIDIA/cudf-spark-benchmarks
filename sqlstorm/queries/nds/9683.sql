
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MIN(dd.d_date) AS first_sale_date,
        MAX(dd.d_date) AS last_sale_date,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
ItemMetrics AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        sd.total_quantity,
        sd.total_net_paid,
        sd.total_orders,
        sd.first_sale_date,
        sd.last_sale_date,
        sd.unique_customers,
        CASE 
            WHEN sd.total_net_paid > 10000 THEN 'High Performer'
            WHEN sd.total_net_paid BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
            ELSE 'Low Performer'
        END AS performance_category
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
)
SELECT 
    performance_category,
    COUNT(*) AS item_count,
    AVG(total_quantity) AS avg_quantity,
    AVG(total_net_paid) AS avg_net_paid,
    MIN(first_sale_date) AS earliest_sale,
    MAX(last_sale_date) AS latest_sale
FROM ItemMetrics
GROUP BY performance_category
ORDER BY item_count DESC;
