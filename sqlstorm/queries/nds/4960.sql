
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    rs.ws_order_number,
    rs.ws_net_profit,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE
        WHEN rs.ws_net_profit IS NULL THEN 'No Profit'
        WHEN COALESCE(cr.total_returned, 0) > 0 THEN 'Returned'
        ELSE 'Sold'
    END AS sale_status
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    (rs.rn = 1 OR rs.ws_order_number IS NULL)
    AND (i.i_current_price > 20.00 OR i.i_current_price IS NULL)
ORDER BY 
    i.i_item_id;
