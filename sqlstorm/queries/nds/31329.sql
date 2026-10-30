
WITH  customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(cs.cs_ext_sales_price) AS total_sales
    FROM customer c
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_counts AS (
    SELECT ca.ca_city, COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
    GROUP BY ca.ca_city
),
ranked_sales AS (
    SELECT cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.total_sales,
           ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY cs.total_sales DESC) as sales_rank
    FROM customer_sales cs
)
SELECT r.c_first_name, r.c_last_name, r.total_sales, ac.customer_count
FROM ranked_sales r
LEFT JOIN address_counts ac ON r.c_customer_sk = ac.customer_count
WHERE ac.customer_count > 10 AND r.sales_rank = 1
ORDER BY r.total_sales DESC
LIMIT 100;
