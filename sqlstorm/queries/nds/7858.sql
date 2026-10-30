
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        ws_ship_date_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_ship_date_sk = d_date_sk
    WHERE 
        d_year = 2023
    GROUP BY 
        ws_bill_customer_sk, 
        ws_ship_date_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        rs.total_sales,
        rs.order_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.ca_state,
    tc.total_sales,
    tc.order_count,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.ca_city, 
    tc.ca_state, 
    tc.total_sales, 
    tc.order_count
ORDER BY 
    tc.total_sales DESC;
