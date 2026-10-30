
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
HighValueReturns AS (
    SELECT
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_value
    FROM
        CustomerReturns cr
    WHERE
        cr.total_return_value > (
            SELECT AVG(total_return_value) FROM CustomerReturns
        )
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(hv.total_returns, 0) AS returns_count,
        COALESCE(hv.total_return_value, 0) AS return_value
    FROM
        customer c
    LEFT JOIN
        HighValueReturns hv ON c.c_customer_sk = hv.sr_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.returns_count,
    tc.return_value,
    CASE
        WHEN tc.return_value > 1000 THEN 'High Value'
        WHEN tc.return_value BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category,
    RANK() OVER (ORDER BY tc.return_value DESC) AS return_rank
FROM 
    TopCustomers tc
ORDER BY 
    tc.return_value DESC
LIMIT 10;
