
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
), 
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS return_count,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(rs.ws_sales_price, 0) AS max_sales_price,
    COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
    COALESCE(cr.return_count, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_value,
    CASE 
        WHEN COALESCE(cr.return_count, 0) = 0 THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status
FROM 
    item i 
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    total_sales_quantity DESC, 
    return_status, 
    max_sales_price DESC;
