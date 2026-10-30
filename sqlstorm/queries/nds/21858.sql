
WITH  item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
store_summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
),
address_join AS (
    SELECT
        c_customer_sk,
        ca_state,
        ca_city,
        ca_zip,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca_state IS NOT NULL
),
final_summary AS (
    SELECT
        a.ca_state,
        a.ca_city,
        COALESCE(total_sales.total_sales, 0) AS store_total_sales,
        COALESCE(web.total_sales, 0) AS web_total_sales,
        (COALESCE(total_sales.total_sales, 0) - COALESCE(web.total_sales, 0)) AS sales_difference
    FROM address_join a
    LEFT JOIN store_summary total_sales ON a.c_customer_sk = total_sales.ss_store_sk
    LEFT JOIN item_sales web ON a.c_customer_sk = web.ws_item_sk
    WHERE a.city_rank <= 3
)

SELECT
    ca_state,
    ca_city,
    SUM(store_total_sales) AS total_store_sales,
    SUM(web_total_sales) AS total_web_sales,
    COUNT(*) AS total_customers,
    CASE
        WHEN SUM(store_total_sales) > SUM(web_total_sales) 
        THEN 'Store' 
        WHEN SUM(store_total_sales) < SUM(web_total_sales) 
        THEN 'Web'
        ELSE 'Equal'
    END AS predominant_sales_channel
FROM final_summary
GROUP BY ca_state, ca_city
HAVING SUM(store_total_sales) > 10000 OR SUM(web_total_sales) > 10000
ORDER BY ca_state, ca_city;
