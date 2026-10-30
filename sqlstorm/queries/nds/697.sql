
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00 AND 
        ws.ws_ship_date_sk > 2450000
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > 2450000
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    COALESCE(c.total_returns, 0) AS total_returns,
    CASE 
        WHEN t.total_sales > 1000 THEN 'High'
        WHEN t.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    TopSales t
LEFT JOIN 
    CustomerReturns c ON t.ws_item_sk = c.sr_item_sk
ORDER BY 
    t.total_sales DESC;
