
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
),
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        MAX(r.ws_net_profit) AS max_profit
    FROM 
        RankedSales r
    WHERE 
        r.rnk = 1
    GROUP BY 
        r.ws_item_sk
),
StoreSalesInfo AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
WebSalesInfo AS (
    SELECT 
        wsi.ws_item_sk,
        SUM(wsi.ws_quantity) AS total_web_quantity,
        SUM(wsi.ws_net_paid) AS total_web_sales
    FROM 
        web_sales wsi
    GROUP BY 
        wsi.ws_item_sk
    HAVING 
        SUM(wsi.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales)
),
DailyReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    COALESCE(si.ss_item_sk, wi.ws_item_sk) AS item_sk,
    COALESCE(si.total_quantity, 0) AS store_quantity,
    COALESCE(si.total_sales, 0) AS store_sales,
    COALESCE(wi.total_web_quantity, 0) AS web_quantity,
    COALESCE(wi.total_web_sales, 0) AS web_sales,
    COALESCE(hr.max_profit, 0) AS high_profit
FROM 
    StoreSalesInfo si
FULL OUTER JOIN 
    WebSalesInfo wi ON si.ss_item_sk = wi.ws_item_sk
FULL OUTER JOIN 
    HighProfitItems hr ON COALESCE(si.ss_item_sk, wi.ws_item_sk) = hr.ws_item_sk
WHERE 
    COALESCE(si.total_quantity, 0) + COALESCE(wi.total_web_quantity, 0) > 0
ORDER BY 
    item_sk
LIMIT 100;
