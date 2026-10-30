
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_date
    HAVING SUM(ws_ext_sales_price) > 1000
), 
RankedCustomers AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        ROW_NUMBER() OVER (ORDER BY hvc.total_spent DESC) AS rank,
        cr.total_returns,
        cr.total_return_amount
    FROM HighValueCustomers hvc
    LEFT JOIN CustomerReturns cr ON hvc.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    rc.rank,
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    COALESCE(rc.total_returns, 0) AS total_returns,
    COALESCE(rc.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN rc.total_return_amount IS NULL THEN 'No Returns'
        ELSE 'Returns Exist'
    END AS return_status
FROM RankedCustomers rc
WHERE rc.rank <= 10
ORDER BY rc.rank;
