
WITH RecursiveCustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_id IS NOT NULL
), 
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
), 
CombinedSales AS (
    SELECT 
        cs.cs_item_sk,
        COALESCE(ws.total_quantity, 0) AS total_quantity,
        COALESCE(ws.total_profit, 0) AS total_profit
    FROM SalesData ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
)
SELECT 
    cc.c_customer_id,
    COUNT(DISTINCT cs.cs_item_sk) AS item_count,
    SUM(cs.total_profit - cs.total_profit) AS profit_loss,
    MAX(cc.cd_purchase_estimate) AS max_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(cc.cd_gender, '-', cc.cd_marital_status), ', ') AS demographic_details
FROM RecursiveCustomerCTE cc
JOIN CombinedSales cs ON cc.c_customer_sk = cs.cs_item_sk
WHERE cc.ranking <= 10 
    AND (cs.total_profit > 100 OR cs.total_profit IS NULL)
GROUP BY cc.c_customer_id, cc.cd_gender, cc.cd_marital_status, cc.cd_purchase_estimate
HAVING SUM(cs.total_quantity) > 0
ORDER BY profit_loss DESC, item_count DESC
LIMIT 50;
