
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS quantity_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 2400 AND 3000
        AND i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk, ws.ws_sales_price
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.quantity_rank = 1
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS total_orders
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
FinalAnalysis AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        COALESCE(cr.total_returned, 0) AS total_returned,
        CASE 
            WHEN ts.total_quantity > 100 THEN 'High'
            WHEN ts.total_quantity > 50 THEN 'Medium'
            ELSE 'Low'
        END AS sale_category,
        CASE 
            WHEN COALESCE(cr.total_orders, 0) = 0 THEN 'No Orders'
            ELSE 'Has Orders'
        END AS order_status
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns cr ON ts.ws_item_sk = cr.cr_item_sk
)
SELECT 
    fa.ws_item_sk,
    fa.total_quantity,
    fa.total_returned,
    fa.sale_category,
    fa.order_status,
    CASE 
        WHEN fa.total_quantity IS NULL THEN 'Unknown'
        ELSE 'Known'
    END AS quantity_status
FROM 
    FinalAnalysis fa
ORDER BY 
    fa.total_quantity DESC, 
    fa.ws_item_sk 
LIMIT 10;
