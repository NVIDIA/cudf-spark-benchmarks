
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
),
sales_data AS (
    SELECT 
        top.c_first_name,
        top.c_last_name,
        COALESCE(SUM(ss.ss_sales_price), 0) AS store_sales,
        COALESCE(COUNT(DISTINCT ss.ss_store_sk), 0) AS stores_visited,
        top.c_customer_sk
    FROM top_customers top
    LEFT JOIN store_sales ss ON top.c_customer_sk = ss.ss_customer_sk
    WHERE top.sales_rank <= 10
    GROUP BY top.c_first_name, top.c_last_name, top.c_customer_sk
)
SELECT 
    a.ca_city,
    SUM(sd.store_sales) AS total_store_sales,
    AVG(sd.stores_visited) AS average_stores_visited,
    MAX(sd.store_sales) AS max_store_sales,
    MIN(sd.store_sales) AS min_store_sales
FROM sales_data sd
JOIN customer_address a ON sd.c_customer_sk = a.ca_address_sk
WHERE a.ca_city IS NOT NULL
GROUP BY a.ca_city
HAVING SUM(sd.store_sales) > 1000
ORDER BY total_store_sales DESC;
