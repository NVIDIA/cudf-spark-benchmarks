WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001)
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001)
    GROUP BY 
        sr_item_sk
    HAVING 
        SUM(sr_return_quantity) > 5 AND SUM(sr_return_amt) > 100
),
FinalSalesData AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity,
        COALESCE(hvr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(hvr.total_returned_amount, 0) AS total_returned_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        HighValueReturns hvr 
    ON 
        rs.ws_item_sk = hvr.sr_item_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    f.ws_item_sk, 
    f.ws_order_number,
    f.ws_sales_price,
    f.total_quantity,
    f.total_returned_quantity,
    f.total_returned_amount,
    CASE 
        WHEN f.total_returned_quantity IS NULL THEN 'No Returns'
        WHEN f.total_returned_quantity > 10 THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_category,
    (f.ws_sales_price * f.total_quantity - f.total_returned_amount) AS net_revenue
FROM 
    FinalSalesData f
WHERE 
    f.total_quantity > (SELECT AVG(total_quantity) FROM FinalSalesData) 
ORDER BY 
    net_revenue DESC
LIMIT 100
;