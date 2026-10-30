
WITH  sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        s.total_sales,
        s.order_count,
        d.d_year
    FROM sales_summary s
    JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON d.d_year = 2023
    WHERE s.sales_rank <= 10
),
customer_addresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ca.ca_city) AS address_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    ca.ca_city,
    ca.ca_state
FROM top_customers tc
LEFT JOIN customer_addresses ca ON tc.c_customer_id = ca.c_customer_id AND ca.address_rank = 1
WHERE tc.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY tc.total_sales DESC;

