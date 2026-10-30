
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM web_sales
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_dep_count ELSE NULL END) AS female_dep_count,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_store_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighProfitSales AS (
    SELECT
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name
    FROM RankedSales r
    JOIN CustomerInfo ci ON r.ws_item_sk = ci.c_customer_sk
    WHERE r.profit_rank = 1
)
SELECT 
    hp.ws_item_sk,
    hp.ws_order_number,
    hp.ws_net_profit,
    ci.c_first_name || ' ' || COALESCE(ci.c_last_name, 'Unknown') AS full_name,
    CASE 
        WHEN ci.female_dep_count IS NULL THEN 'No Dependents'
        ELSE 'Dependents Count: ' || ci.female_dep_count 
    END AS dependent_info,
    COALESCE(ci.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN hp.ws_net_profit > 1000 THEN 'High Profit'
        WHEN hp.ws_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COUNT(*) OVER (PARTITION BY hp.ws_item_sk) AS item_frequency,
    ROW_NUMBER() OVER (PARTITION BY hp.ws_order_number ORDER BY hp.ws_net_profit DESC) AS row_num
FROM HighProfitSales hp
JOIN CustomerInfo ci ON hp.c_customer_sk = ci.c_customer_sk
ORDER BY hp.ws_net_profit DESC NULLS LAST;
