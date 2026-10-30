
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
TopSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.rank_price <= 5
),
CustomerReturns AS (
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_returned_date_sk, sr.sr_item_sk
),
SalesReturns AS (
    SELECT 
        ts.ws_order_number,
        ts.ws_item_sk,
        ts.ws_quantity,
        ts.ws_sales_price,
        COALESCE(cr.total_returned, 0) AS total_returned
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
)
SELECT 
    ts.ws_order_number,
    COUNT(DISTINCT ts.ws_item_sk) AS unique_items_sold,
    SUM(ts.ws_sales_price * ts.ws_quantity) - SUM(ts.total_returned * ts.ws_sales_price) AS net_sales,
    AVG(ts.ws_sales_price) AS avg_sales_price,
    SUM(CASE WHEN sr.total_returned > 0 THEN 1 ELSE 0 END) AS total_returns
FROM 
    SalesReturns ts
LEFT JOIN 
    CustomerReturns sr ON ts.ws_item_sk = sr.sr_item_sk
GROUP BY 
    ts.ws_order_number
HAVING 
    COUNT(DISTINCT ts.ws_item_sk) > 3
ORDER BY 
    net_sales DESC;
