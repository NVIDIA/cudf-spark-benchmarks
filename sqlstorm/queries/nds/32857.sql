
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 5
),
ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
latest_orders AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        MAX(d.d_date) AS max_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        ws.ws_order_number, ws.ws_bill_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ac.ca_city,
    ac.ca_state,
    ac.customer_count,
    lo.max_date
FROM 
    top_customers tc
JOIN 
    address_data ac ON tc.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_current_addr_sk IN (
            SELECT ca.ca_address_sk 
            FROM customer_address ca
        )
    )
LEFT JOIN 
    latest_orders lo ON tc.c_customer_sk = lo.ws_bill_customer_sk
WHERE 
    tc.total_spent BETWEEN 1000 AND 5000
ORDER BY 
    tc.total_spent DESC
LIMIT 10;
