
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ca.ca_city,
        ca.ca_state
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
),
AggregatedSales AS (
    SELECT 
        ci.full_name,
        COUNT(si.ws_order_number) AS total_orders,
        SUM(si.ws_sales_price) AS total_sales,
        SUM(si.ws_sales_price * si.ws_quantity) AS total_revenue,
        AVG(si.ws_sales_price) AS average_order_value
    FROM CustomerInfo ci
    LEFT JOIN SalesInfo si ON ci.ca_city = si.ca_city AND ci.ca_state = si.ca_state
    GROUP BY ci.full_name
)
SELECT 
    full_name,
    total_orders,
    total_sales,
    total_revenue,
    average_order_value,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM AggregatedSales
WHERE total_orders > 0
ORDER BY revenue_rank
LIMIT 10;
