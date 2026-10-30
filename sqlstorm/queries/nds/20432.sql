
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        COALESCE(NULLIF(ws.ws_net_paid_inc_tax, 0), NULL) AS net_paid,
        CASE 
            WHEN ws.ws_ext_discount_amt IS NULL THEN 0 
            ELSE ws.ws_ext_discount_amt
        END AS discount_amount
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),

CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),

SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.total_quantity,
        rs.net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_item_sk = cr.wr_item_sk
    WHERE rs.sales_rank = 1
)

SELECT 
    i.i_item_id,
    COALESCE(swr.total_quantity, 0) AS quantity_sold,
    COALESCE(swr.net_paid, 0) AS net_sales,
    COALESCE(swr.total_returns, 0) AS total_returns,
    COALESCE(swr.total_return_amount, 0) AS return_value,
    CASE 
        WHEN swr.net_paid = 0 THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM item i
LEFT JOIN SalesWithReturns swr ON i.i_item_sk = swr.ws_item_sk
WHERE 
    (swr.total_returns > 5 OR swr.net_paid > 1000 OR i.i_item_desc LIKE '%special%')
ORDER BY 
    i.i_item_id, 
    sales_status DESC
LIMIT 10;

