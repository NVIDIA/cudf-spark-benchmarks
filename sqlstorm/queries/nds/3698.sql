
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amt
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rp.total_return_qty, 0) AS total_returns,
    COALESCE(rp.total_return_amt, 0) AS total_return_amount,
    SUM(rs.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    AVG(CASE WHEN rs.ws_ext_sales_price > 0 THEN rs.ws_sales_price / NULLIF(rs.ws_ext_sales_price, 0) END) AS price_to_sales_ratio
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rn = 1
LEFT JOIN 
    TotalReturns rp ON i.i_item_sk = rp.cr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
GROUP BY 
    i.i_item_id, rp.total_return_qty, rp.total_return_amt
ORDER BY 
    total_sales DESC
LIMIT 10;
