
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned,
        COUNT(DISTINCT sr.sr_returned_date_sk) AS return_days_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
HighValueReturns AS (
    SELECT 
        cr.sr_item_sk,
        cr.total_returned,
        cr.return_days_count,
        i.i_item_desc,
        i.i_current_price,
        (cr.total_returned * i.i_current_price) AS total_return_value
    FROM 
        CustomerReturns cr
    JOIN 
        item i ON cr.sr_item_sk = i.i_item_sk
    WHERE 
        cr.total_returned > 0 AND (cr.total_returned * i.i_current_price) > 100
),
OrderDetails AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        hvr.total_returned,
        hvr.return_days_count,
        hvr.total_return_value
    FROM 
        RankedSales rs
    LEFT JOIN 
        HighValueReturns hvr ON rs.ws_item_sk = hvr.sr_item_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    od.ws_order_number,
    COUNT(DISTINCT od.ws_item_sk) AS unique_items,
    SUM(od.ws_sales_price) AS total_sales,
    COALESCE(SUM(od.total_return_value), 0) AS total_return_value,
    SUM(CASE WHEN od.total_returned IS NOT NULL THEN od.total_returned ELSE 0 END) AS total_returned_quantity,
    SUM(CASE WHEN od.return_days_count > 0 THEN 1 ELSE 0 END) AS days_with_returns
FROM 
    OrderDetails od
GROUP BY 
    od.ws_order_number
HAVING 
    SUM(od.ws_sales_price) > 500
ORDER BY 
    total_sales DESC;
