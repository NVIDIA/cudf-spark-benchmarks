
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price ASC) AS dense_sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_order_number = ws.ws_order_number)
),
HighValueReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 2
    GROUP BY 
        cr.cr_item_sk 
    HAVING 
        SUM(cr.cr_return_amount) > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = cr.cr_item_sk)
),
FinalJoin AS (
    SELECT 
        it.i_item_id,
        it.i_item_desc,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        r.ws_sales_price,
        CASE 
            WHEN r.sales_rank = 1 THEN 'Top Sale'
            ELSE 'Regular Sale'
        END AS sale_type
    FROM 
        item it
    LEFT JOIN RankedSales r ON it.i_item_sk = r.ws_item_sk
    LEFT JOIN HighValueReturns rs ON it.i_item_sk = rs.cr_item_sk
)
SELECT 
    fj.i_item_id,
    fj.i_item_desc,
    fj.total_returned_amount,
    fj.sale_type,
    CASE 
        WHEN fj.total_returned_amount > 1000 THEN 'High Return'
        WHEN fj.total_returned_amount BETWEEN 500 AND 1000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_value_category
FROM 
    FinalJoin fj
WHERE 
    fj.total_returned_amount IS NOT NULL
ORDER BY 
    fj.total_returned_amount DESC;
