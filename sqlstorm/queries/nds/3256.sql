
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT *
    FROM customer_sales
    WHERE sales_rank <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state,
        COALESCE(ca.ca_zip, 'ZIP NOT AVAILABLE') AS zip_code,
        c.c_customer_sk
    FROM 
        customer_address ca
    INNER JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    ca.ca_city,
    ca.ca_state,
    ca.zip_code
FROM 
    top_customers tc
LEFT JOIN 
    customer_addresses ca ON tc.c_customer_sk = ca.c_customer_sk
WHERE 
    tc.total_sales > (SELECT AVG(total_sales) FROM top_customers) 
ORDER BY 
    tc.total_sales DESC;
