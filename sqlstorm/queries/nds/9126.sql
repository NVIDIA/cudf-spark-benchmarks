WITH customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS city_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2459626 AND 2459650   
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        ss.total_sales,
        ss.total_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM customer_details cd
    JOIN sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    tc.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM top_customers tc
JOIN customer_details cd ON tc.c_customer_sk = cd.c_customer_sk
JOIN customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
WHERE tc.sales_rank <= 10  
ORDER BY tc.total_sales DESC;