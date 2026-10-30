
WITH SalesSummary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) as rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 AND d.d_moy IN (1, 2, 3)
    GROUP BY ws.ws_item_sk
),
TopSalesItems AS (
    SELECT ss.ws_item_sk, total_quantity, total_sales, total_discount
    FROM SalesSummary ss
    WHERE ss.rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    tsi.total_discount,
    COALESCE(sr_amounts.total_returned_amount, 0) AS total_returned_amount,
    (tsi.total_sales - COALESCE(sr_amounts.total_returned_amount, 0)) AS net_sales
FROM TopSalesItems tsi
JOIN item i ON tsi.ws_item_sk = i.i_item_sk
LEFT JOIN (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
) sr_amounts ON tsi.ws_item_sk = sr_amounts.sr_item_sk
ORDER BY tsi.total_sales DESC;
