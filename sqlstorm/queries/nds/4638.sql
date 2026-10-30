WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > (
        SELECT AVG(total_sales) FROM customer_sales
    )
),
customer_address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM customer_address ca
),
customer_with_address AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        tc.total_sales,
        tc.order_count
    FROM top_customers tc
    LEFT JOIN customer_address_info ca ON tc.c_customer_sk = ca.ca_address_sk
)
SELECT 
    cwa.c_first_name,
    cwa.c_last_name,
    COALESCE(cwa.ca_city, 'Unknown') AS city,
    COALESCE(cwa.ca_state, 'Unknown') AS state,
    COALESCE(cwa.ca_zip, 'N/A') AS zip,
    cwa.total_sales,
    cwa.order_count
FROM customer_with_address cwa
WHERE cwa.order_count > 5 AND cwa.total_sales > 500.00
ORDER BY cwa.total_sales DESC
LIMIT 10;