WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_date = cast('2002-10-01' as date)
        )
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
        )
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(rs.ws_quantity, 0) AS total_quantity_sold,
    COALESCE(cr.total_returned, 0) AS total_quantity_returned,
    (COALESCE(rs.ws_quantity, 0) - COALESCE(cr.total_returned, 0)) AS net_quantity_sold,
    COALESCE(rs.ws_sales_price, 0) AS last_sales_price,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.SalesRank = 1
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    i.i_current_price > (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_current_price IS NOT NULL
    )
ORDER BY 
    net_quantity_sold DESC, 
    last_sales_price DESC
LIMIT 10;