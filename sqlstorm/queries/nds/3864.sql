
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales_quantity,
        sd.total_net_paid
    FROM SalesData sd
    WHERE sd.rank <= 10
),
CustomerReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT 
        tp.ws_item_sk,
        tp.total_sales_quantity,
        tp.total_net_paid,
        COALESCE(crd.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(crd.total_returned_amt, 0) AS total_returned_amt,
        (tp.total_net_paid - COALESCE(crd.total_returned_amt, 0)) AS net_revenue
    FROM TopProducts tp
    LEFT JOIN CustomerReturnData crd ON tp.ws_item_sk = crd.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fr.total_sales_quantity,
    fr.total_net_paid,
    fr.total_returned_quantity,
    fr.total_returned_amt,
    fr.net_revenue,
    CASE
        WHEN fr.net_revenue < 0 THEN 'Loss'
        WHEN fr.net_revenue = 0 THEN 'Break-even'
        ELSE 'Profit' 
    END AS revenue_status
FROM FinalReport fr
JOIN item i ON fr.ws_item_sk = i.i_item_sk
ORDER BY fr.net_revenue DESC;
