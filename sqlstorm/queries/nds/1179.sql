
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
), 
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
), 
SalesWithReturns AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(tr.total_returns, 0) AS total_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        TotalReturns tr ON ws.ws_item_sk = tr.cr_item_sk
), 
SalesSummary AS (
    SELECT 
        wsr.ws_item_sk,
        SUM(wsr.ws_sales_price * wsr.ws_quantity) AS total_sales,
        SUM(wsr.total_returns) AS total_returns
    FROM 
        SalesWithReturns wsr
    GROUP BY 
        wsr.ws_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_sales,
    ss.total_returns,
    (ss.total_sales - ss.total_returns) AS net_sales,
    (ss.total_sales / NULLIF(NULLIF(ss.total_returns, 0), 0) + 1) AS return_rate
FROM 
    SalesSummary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 10
    AND i.i_color IS NOT NULL
ORDER BY 
    net_sales DESC
LIMIT 10;
