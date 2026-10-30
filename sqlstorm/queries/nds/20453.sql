
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 365
    UNION ALL
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        cs_quantity, 
        cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) as rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 1 AND 365
    UNION ALL
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        ss_quantity, 
        ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) as rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 1 AND 365
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        DENSE_RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY cd.cd_purchase_estimate DESC) as addr_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_first_name IS NOT NULL
),
top_customers AS (
    SELECT 
        c.c_customer_sk, 
        SUM(s.ws_net_profit) AS total_profit
    FROM sales_data s
    JOIN customer_info c ON s.ws_item_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(s.ws_net_profit) > (
        SELECT AVG(total_profit) 
        FROM (SELECT SUM(ws_net_profit) AS total_profit FROM web_sales GROUP BY ws_item_sk) AS avg_profit
    )
)
SELECT DISTINCT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(td.total_profit, 0) AS total_profit,
    CASE 
        WHEN ci.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN ci.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM customer_info ci
LEFT JOIN top_customers td ON ci.c_customer_sk = td.c_customer_sk
WHERE ci.addr_rank = 1
ORDER BY total_profit DESC, ci.c_last_name, ci.c_first_name;
