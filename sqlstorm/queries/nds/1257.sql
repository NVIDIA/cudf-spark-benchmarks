
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
), 
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
), 
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc, 
        i.i_brand,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM item i 
    LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
)

SELECT 
    tsi.ws_item_sk,
    id.i_item_desc,
    id.i_brand,
    tsi.total_quantity,
    tsi.total_sales,
    id.total_returns,
    id.total_return_value,
    (tsi.total_sales - id.total_return_value) AS net_sales_value
FROM TopSellingItems tsi
JOIN ItemDetails id ON tsi.ws_item_sk = id.i_item_sk
WHERE id.total_returns < 5
ORDER BY net_sales_value DESC
LIMIT 20;
