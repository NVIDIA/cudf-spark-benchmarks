
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        d.d_year AS sales_year,
        ca.ca_state AS state
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2023
    GROUP BY c.c_customer_id, d.d_year, ca.ca_state
), state_summary AS (
    SELECT 
        state,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        AVG(total_sales) AS avg_sales,
        SUM(avg_net_profit) AS total_avg_profit
    FROM sales_summary
    GROUP BY state
)
SELECT 
    state,
    unique_customers,
    avg_sales,
    total_avg_profit
FROM state_summary
ORDER BY unique_customers DESC, avg_sales DESC
LIMIT 10;
