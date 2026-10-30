
WITH RankedWebSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TotalSales AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_id
),
CustomerReturns AS (
    SELECT 
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE WHEN cd.cd_credit_rating IS NOT NULL THEN 1 ELSE 0 END) AS credit_rated_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    wa.w_warehouse_id,
    wm.sm_ship_mode_id,
    cf.customer_count,
    cf.credit_rated_customers,
    wb.ws_order_number,
    wb.ws_item_sk,
    wb.ws_net_profit,
    ts.total_store_profit
FROM 
    warehouse wa
LEFT JOIN 
    ship_mode wm ON wm.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE 'Air%')
JOIN 
    RankedWebSales wb ON wb.rn = 1
JOIN 
    TotalSales ts ON ts.total_store_profit > 100000
LEFT JOIN 
    CustomerDemographics cf ON cf.cd_demo_sk = (SELECT cd_demo_sk FROM customer_demographics ORDER BY cd_purchase_estimate DESC LIMIT 1)
WHERE 
    wb.ws_net_profit > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws WHERE ws.ws_item_sk = wb.ws_item_sk)
    AND ts.total_store_profit IS NOT NULL
ORDER BY 
    ts.total_store_profit DESC, cf.customer_count ASC;
