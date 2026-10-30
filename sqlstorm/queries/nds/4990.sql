
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
),
TotalSales AS (
    SELECT 
        i.i_item_id,
        COUNT(ts.ws_order_number) AS order_count,
        SUM(ts.ws_ext_sales_price) AS total_revenue,
        ts.ws_item_sk
    FROM 
        item i
    LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
    GROUP BY 
        i.i_item_id, ts.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    ts.ws_item_sk,
    i.i_item_id,
    ts.total_revenue,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (ts.total_revenue - COALESCE(cr.total_returns, 0) * i.i_wholesale_cost) AS net_revenue_after_returns
FROM 
    TotalSales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON cr.sr_item_sk = ts.ws_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    net_revenue_after_returns DESC
LIMIT 100;
