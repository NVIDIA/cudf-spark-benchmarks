
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451092 AND 2451191
),
HighValueItems AS (
    SELECT
        i_item_sk,
        i_product_name,
        AVG(ws_sales_price) AS avg_sales_price
    FROM RankedSales
    JOIN item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE price_rank = 1
    GROUP BY i_item_sk, i_product_name
    HAVING AVG(ws_sales_price) > 50
),
StoreReturnsSummary AS (
    SELECT
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk >= 2451092
    GROUP BY sr_item_sk
)
SELECT
    HVI.i_item_sk,
    HVI.i_product_name,
    HVI.avg_sales_price,
    COALESCE(SRS.total_returns, 0) AS total_returns,
    COALESCE(SRS.total_return_amount, 0) AS total_return_amount,
    CASE
        WHEN COALESCE(SRS.total_return_amount, 0) > 100 THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status,
    DENSE_RANK() OVER (ORDER BY HVI.avg_sales_price DESC) AS price_rank,
    HVI.avg_sales_price * 2 - (SELECT AVG(avg_sales_price) FROM HighValueItems WHERE avg_sales_price IS NOT NULL) AS adjusted_price
FROM HighValueItems HVI
LEFT JOIN StoreReturnsSummary SRS ON HVI.i_item_sk = SRS.sr_item_sk
WHERE HVI.avg_sales_price IS NOT NULL
ORDER BY adjusted_price DESC
LIMIT 10;
