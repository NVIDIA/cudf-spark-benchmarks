
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
address_ranked AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS city_rank
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
date_filter AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq
    FROM date_dim d 
    WHERE d.d_year >= 2020 AND d.d_year <= 2023
),
filtered_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales,
    ar.ca_city,
    ar.ca_state,
    fs.total_quantity,
    fs.net_profit
FROM sales_hierarchy sh
JOIN address_ranked ar ON ar.city_rank = 1 
JOIN filtered_sales fs ON fs.ws_item_sk IN (
    SELECT s.cs_item_sk 
    FROM catalog_sales s 
    WHERE s.cs_order_number = (SELECT MAX(cs_order_number) FROM catalog_sales)
)
WHERE sh.sales_rank <= 10
ORDER BY sh.total_sales DESC, fs.net_profit DESC;
