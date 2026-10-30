
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        (ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.net_sales_price) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS total_items,
        MAX(rs.rank_sales) AS max_rank
    FROM 
        RankedSales rs
    GROUP BY 
        rs.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr.sr_returned_date_sk, 
        sr.sr_item_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned_qty
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk, sr.sr_returned_date_sk
)
SELECT 
    ss.ws_order_number,
    ss.total_sales AS order_total,
    ss.total_items,
    cr.total_returned_qty,
    CASE 
        WHEN cr.total_returned_qty > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    SalesSummary ss
LEFT JOIN 
    CustomerReturns cr ON ss.ws_order_number = cr.sr_item_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC;
