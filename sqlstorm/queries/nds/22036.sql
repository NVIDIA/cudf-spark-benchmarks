
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 0
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_paid
    FROM RankedSales rs
    WHERE rs.sales_rank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.ws_net_paid, 0) AS highest_net_paid,
    COALESCE(cr.total_returned, 0) AS total_returns,
    CASE 
        WHEN COALESCE(ts.ws_net_paid, 0) = 0 THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA') > 0
    AND (SELECT COUNT(*) FROM warehouse w WHERE w.w_country = 'USA') > 0
    AND (SELECT AVG(hd_dep_count) FROM household_demographics WHERE hd_income_band_sk IS NOT NULL) > 2
ORDER BY highest_net_paid DESC, total_returns ASC
LIMIT 100;
