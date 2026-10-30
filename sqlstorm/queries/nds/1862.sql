
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales AS ws
    INNER JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00 AND
        i.i_brand_id IN (SELECT i_brand_id FROM item GROUP BY i_brand_id HAVING COUNT(*) > 50)
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TotalSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_item_sk
),
SalesSummary AS (
    SELECT 
        ts.ws_item_sk,
        COALESCE(tr.total_returns, 0) AS total_returns,
        ts.total_quantity_sold,
        ts.total_sales,
        CASE 
            WHEN ts.total_sales = 0 THEN 0 
            ELSE (COALESCE(tr.total_returns, 0) / ts.total_quantity_sold) 
        END AS return_rate
    FROM 
        TotalSales ts
    LEFT JOIN 
        AggregateReturns tr ON ts.ws_item_sk = tr.sr_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_returns,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.return_rate
FROM 
    SalesSummary ss
WHERE 
    ss.return_rate > 0.1
ORDER BY 
    ss.return_rate DESC
LIMIT 10;
