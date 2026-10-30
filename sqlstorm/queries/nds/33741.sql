
WITH  sales_hierarchy AS (
    SELECT ss_store_sk, ss_item_sk, ss_ticket_number, ss_quantity, ss_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_sold_date_sk DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
    )
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city,
           cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
top_sales_item AS (
    SELECT ss_item_sk,
           SUM(ss_sales_price * ss_quantity) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ss_item_sk
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.ca_city,
       ci.cd_gender, ci.cd_marital_status, ci.hd_income_band_sk,
       sh.ss_item_sk, sh.ss_ticket_number, sh.ss_quantity, sh.ss_sales_price,
       th.total_sales
FROM customer_info ci
INNER JOIN sales_hierarchy sh ON ci.c_customer_sk = sh.ss_store_sk
JOIN top_sales_item th ON sh.ss_item_sk = th.ss_item_sk
LEFT JOIN (SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_preferred_cust_flag = 'Y') AS pref_customers
ON ci.c_customer_sk = pref_customers.c_customer_sk
WHERE ci.hd_income_band_sk IS NOT NULL
ORDER BY ci.ca_city, th.total_sales DESC;
