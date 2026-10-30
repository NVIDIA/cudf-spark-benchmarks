
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_customer_sk,
           SUM(ss_net_paid) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_paid) > 1000
    UNION ALL
    SELECT s.ss_customer_sk,
           sh.total_sales + s.ss_net_paid AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY s.ss_customer_sk ORDER BY (sh.total_sales + s.ss_net_paid) DESC) AS sales_rank
    FROM sales_hierarchy sh
    JOIN store_sales s ON sh.ss_customer_sk = s.ss_customer_sk
    WHERE sh.sales_rank < 10
),
high_value_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(cd.cd_gender, 'N/A') AS gender,
           ROUND(SUM(ss_ext_sales_price), 2) AS lifetime_value
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING ROUND(SUM(ss_ext_sales_price), 2) > (
        SELECT AVG(lifetime_value)
        FROM (
            SELECT ROUND(SUM(ss_ext_sales_price), 2) AS lifetime_value
            FROM customer c2
            JOIN store_sales ss2 ON c2.c_customer_sk = ss2.ss_customer_sk
            GROUP BY c2.c_customer_sk
        ) AS avg_values
    )
),
sales_summary AS (
    SELECT s.ss_store_sk,
           SUM(s.ss_net_paid) AS total_sales,
           AVG(ss_ext_discount_amt) AS average_discount,
           COUNT(DISTINCT s.ss_customer_sk) AS unique_customers
    FROM store_sales s
    GROUP BY s.ss_store_sk
)
SELECT s.ss_store_sk AS store_id,
       s.total_sales,
       s.average_discount,
       s.unique_customers,
       hc.c_first_name,
       hc.c_last_name,
       hc.gender
FROM sales_summary s
JOIN high_value_customers hc ON s.ss_store_sk = hc.c_customer_sk
WHERE s.unique_customers > 10
ORDER BY s.total_sales DESC
LIMIT 10 OFFSET 5;
