
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ws.ws_ext_sales_price) > 1000
),
ReturnRates AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_spent,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        (COALESCE(cr.total_returns, 0) * 1.0 / NULLIF(COUNT(ws.ws_order_number), 0)) AS return_rate
    FROM HighValueCustomers hvc
    LEFT JOIN CustomerReturns cr ON hvc.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY hvc.c_customer_sk, hvc.total_spent, cr.total_returns, cr.total_return_value
)
SELECT 
    r.c_customer_sk,
    r.total_spent,
    r.total_returns,
    r.total_return_value,
    r.return_rate,
    CASE 
        WHEN r.return_rate IS NULL THEN 'No Data'
        WHEN r.return_rate > 0.5 THEN 'High'
        ELSE 'Low'
    END AS return_status
FROM ReturnRates r
ORDER BY r.return_rate DESC NULLS LAST
LIMIT 10;
