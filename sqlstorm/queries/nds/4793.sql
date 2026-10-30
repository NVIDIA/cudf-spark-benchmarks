
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        AVG(sr_return_amt_inc_tax) AS avg_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    isales.i_item_sk,
    isales.i_item_desc,
    isales.total_sold,
    CASE 
        WHEN ar.total_returned IS NOT NULL THEN (isales.total_profit - ar.total_returned * (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL)) 
        ELSE isales.total_profit 
    END AS net_profit_after_returns,
    r.rank
FROM 
    ItemSales isales
LEFT JOIN 
    AggregateReturns ar ON isales.i_item_sk = ar.sr_item_sk
LEFT JOIN 
    (SELECT ws_item_sk, COUNT(DISTINCT ws_order_number) AS order_count
     FROM web_sales
     GROUP BY ws_item_sk) order_counts ON isales.i_item_sk = order_counts.ws_item_sk
JOIN 
    (SELECT ws_item_sk, ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS rank
     FROM web_sales
     GROUP BY ws_item_sk) r ON isales.i_item_sk = r.ws_item_sk
WHERE 
    isales.total_sold > 0
ORDER BY 
    net_profit_after_returns DESC,
    isales.total_sold DESC
LIMIT 10;
