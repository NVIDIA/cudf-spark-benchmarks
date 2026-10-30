
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amount
    FROM customer AS c
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_web_site_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY ws.ws_net_paid_inc_tax DESC) AS row_num
    FROM web_sales AS ws
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
TopSales AS (
    SELECT
        ws_web_site_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_net_paid
    FROM SalesData
    WHERE row_num <= 5
    GROUP BY ws_web_site_sk
)
SELECT
    ws.web_site_id,
    COALESCE(ts.total_quantity_sold, 0) AS quantity_sold,
    COALESCE(ts.total_net_paid, 0) AS net_paid,
    cr.total_return_quantity,
    cr.total_return_amount
FROM web_site AS ws
LEFT JOIN TopSales AS ts ON ws.web_site_sk = ts.ws_web_site_sk
LEFT JOIN CustomerReturns AS cr ON cr.c_customer_id = 'CUST12345' 
ORDER BY net_paid DESC;
