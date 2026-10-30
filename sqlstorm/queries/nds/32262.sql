
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
ranked_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
aggregated_returns AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    ca.ca_address_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(r.total_quantity, 0) AS total_sales,
    COALESCE(a.total_returns, 0) AS total_returns,
    (COALESCE(r.total_quantity, 0) - COALESCE(a.total_returns, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(r.total_quantity, 0) - COALESCE(a.total_returns, 0) > 0 THEN 'Positive Sales'
        WHEN COALESCE(r.total_quantity, 0) - COALESCE(a.total_returns, 0) < 0 THEN 'Negative Sales'
        ELSE 'No Sales'
    END AS sales_status
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN ranked_sales r ON r.ws_item_sk IN (
    SELECT i_item_sk FROM item
    WHERE i_formulation LIKE '%Organic%' 
)
LEFT JOIN aggregated_returns a ON a.cr_item_sk = r.ws_item_sk
WHERE c.c_current_cdemo_sk IN (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_gender = 'F' AND cd_marital_status = 'M' 
)
GROUP BY ca.ca_address_id, c.c_first_name, c.c_last_name, r.total_quantity, a.total_returns
ORDER BY net_sales DESC
LIMIT 10;
