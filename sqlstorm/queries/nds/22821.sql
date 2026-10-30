
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2023 AND 
        (ws.ws_net_paid_inc_ship IS NOT NULL OR ws.ws_net_paid > 0)
    GROUP BY 
        ws.ws_item_sk
), 
HighSalesItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1 AND 
        rs.total_sales > 1000
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    hi.total_quantity,
    hi.total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    CASE 
        WHEN hi.total_sales >= 5000 THEN 'High Value'
        WHEN hi.total_sales >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category,
    CASE 
        WHEN hi.total_sales IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS sales_status
FROM 
    HighSalesItems hi
LEFT JOIN 
    item i ON hi.ws_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON hi.ws_item_sk = cr.sr_item_sk
ORDER BY 
    hi.total_sales DESC
LIMIT 10;
