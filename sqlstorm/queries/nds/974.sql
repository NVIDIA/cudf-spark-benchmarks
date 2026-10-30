
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) AS rn,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_sales_price
),
HighValueReturns AS (
    SELECT 
        cr.cr_order_number,
        SUM(cr.cr_return_amount) AS total_returned,
        COUNT(cr.cr_item_sk) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_order_number
)
SELECT 
    cs.cs_order_number,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COALESCE(svr.total_returned, 0) AS total_returns,
    COALESCE(hr.return_count, 0) AS return_items_count,
    CASE 
        WHEN SUM(cs.cs_ext_sales_price) > COALESCE(svr.total_returned, 0) THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profitability_status
FROM 
    catalog_sales cs
LEFT JOIN 
    HighValueReturns svr ON cs.cs_order_number = svr.cr_order_number
LEFT JOIN 
    (SELECT cr.cr_order_number, COUNT(cr.cr_item_sk) AS return_count FROM catalog_returns cr GROUP BY cr.cr_order_number) hr ON cs.cs_order_number = hr.cr_order_number
WHERE 
    cs.cs_sales_price IS NOT NULL
GROUP BY 
    cs.cs_order_number, svr.total_returned, hr.return_count
HAVING 
    SUM(cs.cs_ext_sales_price) > 1000 OR COALESCE(svr.total_returned, 0) > 100
ORDER BY 
    total_sales DESC, profitability_status;
