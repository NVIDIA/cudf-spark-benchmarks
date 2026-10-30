
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank,
        CASE 
            WHEN SUM(ws.ws_net_paid) >= 500 THEN 'High Value'
            WHEN SUM(ws.ws_net_paid) BETWEEN 100 AND 499 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
MonthlyReturns AS (
    SELECT 
        EXTRACT(MONTH FROM d.d_date) AS month,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY EXTRACT(MONTH FROM d.d_date)
),
FinalAnalysis AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        r.value_category,
        m.month,
        COALESCE(m.total_returns, 0) AS total_returns,
        COALESCE(m.total_return_amt, 0) AS total_return_amt
    FROM RankedSales r
    FULL OUTER JOIN MonthlyReturns m ON r.rank = m.month
    WHERE r.total_net_paid IS NOT NULL OR m.total_returns IS NOT NULL
)
SELECT 
    fa.ws_item_sk,
    fa.total_quantity,
    fa.total_net_paid,
    fa.value_category,
    fa.month,
    fa.total_returns,
    fa.total_return_amt,
    CASE 
        WHEN fa.total_net_paid > 1000 THEN 'High Profitability'
        ELSE 'Regular Profitability'
    END AS profitability_status
FROM FinalAnalysis fa
WHERE (fa.total_quantity > 10 AND fa.value_category != 'Low Value')
   OR (fa.total_returns > 5 AND fa.value_category = 'Medium Value')
ORDER BY fa.total_net_paid DESC, fa.month ASC;
