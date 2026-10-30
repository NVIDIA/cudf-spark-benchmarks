
WITH  sales_data AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM sales_data sd
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_education_status, cd.cd_purchase_estimate, hd.hd_income_band_sk, 
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_customer_sk, 
    ci.c_first_name,
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status,
    CASE 
        WHEN rs.total_net_profit IS NULL THEN 0 
        ELSE rs.total_net_profit 
    END AS total_net_profit,
    CASE 
        WHEN rs.total_quantity IS NULL THEN 0 
        ELSE rs.total_quantity 
    END AS total_quantity,
    (SELECT COUNT(DISTINCT sr_ticket_number) 
     FROM store_returns 
     WHERE sr_customer_sk = ci.c_customer_sk 
       AND sr_return_quantity > 0) AS total_returns
FROM customer_info ci
LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk
WHERE ci.cd_marital_status = 'M' 
  AND (ci.hd_income_band_sk IS NULL OR ci.hd_income_band_sk BETWEEN 1 AND 10)
ORDER BY total_net_profit DESC 
LIMIT 100;
