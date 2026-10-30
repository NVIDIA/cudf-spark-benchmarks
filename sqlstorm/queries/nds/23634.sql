
WITH  SalesCTE AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
DemographicRatings AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase,
        COUNT(cd.cd_dep_count) AS dependent_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_marital_status = 'M' 
    GROUP BY 
        cd.cd_demo_sk
),
FinalSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(ss.total_orders, 0) AS order_count,
        COALESCE(ss.total_net_profit, 0) AS net_profit,
        COALESCE(dr.avg_purchase, 0) AS avg_purchase,
        COALESCE(dr.dependent_count, 0) AS dependents
    FROM 
        item 
    LEFT JOIN SalesCTE s ON item.i_item_sk = s.ws_item_sk 
    LEFT JOIN CustomerStats ss ON ss.c_customer_sk = s.ws_order_number 
    LEFT JOIN DemographicRatings dr ON item.i_manufact_id = dr.cd_demo_sk
    WHERE 
        item.i_current_price > 0 
        AND (COALESCE(ss.total_orders, 0) > 10 OR COALESCE(dr.avg_purchase, 0) > 100)
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.order_count,
    f.net_profit,
    f.avg_purchase,
    f.dependents
FROM 
    FinalSales f
WHERE 
    f.order_count IS NOT NULL
    AND (f.net_profit > 2000 OR f.dependents IS NOT NULL)
ORDER BY 
    f.net_profit DESC;
