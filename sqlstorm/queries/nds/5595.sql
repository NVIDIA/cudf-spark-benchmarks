
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_quantity, 
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSales AS (
    SELECT 
        ws_ship_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
StoreSales AS (
    SELECT 
        ss_customer_sk, 
        SUM(ss_net_profit) AS total_net_profit
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
CombinedSales AS (
    SELECT 
        COALESCE(ws.ws_ship_customer_sk, ss.ss_customer_sk) AS customer_sk,
        COALESCE(ws.total_net_profit, 0) + COALESCE(ss.total_net_profit, 0) AS overall_net_profit
    FROM 
        WebSales ws
    FULL OUTER JOIN 
        StoreSales ss ON ws.ws_ship_customer_sk = ss.ss_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returns, 0) AS total_return_count,
        cs.overall_net_profit
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        CombinedSales cs ON c.c_customer_sk = cs.customer_sk
)
SELECT 
    f.c_customer_id,
    f.total_returned_quantity,
    f.total_return_count,
    f.overall_net_profit
FROM 
    FinalReport f
WHERE 
    f.overall_net_profit > 1000
ORDER BY 
    overall_net_profit DESC
LIMIT 100;
