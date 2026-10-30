
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        i.i_item_desc
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    WHERE sd.sales_rank <= 10
),
PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim) 
        AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY p.p_promo_id
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalResults AS (
    SELECT 
        ts.i_item_desc,
        ts.total_quantity,
        ts.total_net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ps.total_revenue, 0) AS total_promo_revenue
    FROM TopSales ts
    LEFT JOIN CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
    LEFT JOIN PromotionStats ps ON ps.order_count > 0
)
SELECT 
    *,
    CASE 
        WHEN total_returns > 0 THEN 
            (total_returned_amount / total_net_paid) * 100 
        ELSE 0 
    END AS return_percentage,
    CONCAT(i_item_desc, ' (', total_quantity, ' sold)') AS item_summary
FROM FinalResults
ORDER BY total_net_paid DESC;
