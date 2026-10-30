
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= 2450000
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_amt_inc_tax) > 1000
),
CombinedSales AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_quantity) AS total_quantity_sold,
        SUM(w.ws_sales_price) AS total_sales_value
    FROM web_sales w
    LEFT JOIN store_sales s ON w.ws_item_sk = s.ss_item_sk
    GROUP BY w.ws_item_sk
),
DetailedReturns AS (
    SELECT 
        r.cr_item_sk,
        COUNT(r.cr_order_number) AS return_count,
        AVG(r.cr_return_amount) AS avg_return_amt
    FROM catalog_returns r
    GROUP BY r.cr_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.total_quantity_sold,
    cs.total_sales_value,
    COALESCE(rn.rn, 0) AS rank,
    COALESCE(hr.total_returned_value, 0) AS total_returned_value,
    COALESCE(dr.return_count, 0) AS return_count,
    COALESCE(dr.avg_return_amt, 0) AS avg_return_amt
FROM CombinedSales cs
LEFT JOIN RankedSales rn ON cs.ws_item_sk = rn.ws_item_sk AND rn.rn = 1
LEFT JOIN HighValueReturns hr ON cs.ws_item_sk = hr.sr_item_sk
LEFT JOIN DetailedReturns dr ON cs.ws_item_sk = dr.cr_item_sk
WHERE cs.total_quantity_sold IS NOT NULL
ORDER BY cs.total_sales_value DESC
LIMIT 10;
