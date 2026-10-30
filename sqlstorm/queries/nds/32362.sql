
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_state,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(cs_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN (
        SELECT 
            cs_bill_customer_sk,
            cs_order_number,
            SUM(cs_net_profit) AS cs_net_profit
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk, cs_order_number
    ) cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_demo_sk, cd.cd_marital_status, cd.cd_gender, ca.ca_state
),
TopSales AS (
    SELECT 
        si.ws_item_sk,
        SUM(si.ws_net_profit) AS total_item_profit
    FROM web_sales si
    JOIN SalesCTE s ON si.ws_item_sk = s.ws_item_sk
    WHERE s.rn <= 5
    GROUP BY si.ws_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.total_orders,
    ci.total_net_profit,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        WHEN ci.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    COALESCE(ta.total_item_profit, 0) AS item_profit
FROM CustomerInfo ci
LEFT JOIN TopSales ta ON ci.c_customer_sk = ta.ws_item_sk
WHERE ci.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerInfo)
AND ci.ca_state IS NOT NULL
ORDER BY ci.total_net_profit DESC
LIMIT 100;
