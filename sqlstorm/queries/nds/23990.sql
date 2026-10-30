
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank,
        COALESCE(SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 0) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
SalesReturns AS (
    SELECT 
        cr.cr_item_sk,
        cr.cr_order_number,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk, cr.cr_order_number
),
CombinedSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.price_rank,
        rs.total_quantity,
        COALESCE(sr.total_returns, 0) AS total_returns
    FROM RankedSales rs
    LEFT JOIN SalesReturns sr 
        ON rs.ws_item_sk = sr.cr_item_sk AND rs.ws_order_number = sr.cr_order_number
)
SELECT 
    cs.ws_item_sk,
    cs.ws_order_number,
    cs.ws_sales_price,
    cs.total_quantity,
    cs.total_returns,
    CASE 
        WHEN cs.price_rank = 1 THEN 'Top Seller' 
        ELSE 'Regular' 
    END AS sale_status,
    CASE 
        WHEN cs.total_returns > (cs.total_quantity / 10) THEN 'High Return Rate' 
        ELSE 'Acceptable Return Rate' 
    END AS return_status
FROM CombinedSales cs
WHERE cs.total_quantity > 10
ORDER BY cs.total_returns DESC, cs.ws_sales_price ASC
LIMIT 100;
