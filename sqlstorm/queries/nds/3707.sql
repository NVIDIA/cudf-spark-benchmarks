
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rnk
    FROM 
        customer c 
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

TopReturningCustomers AS (
    SELECT 
        c.*,
        cr.total_returns,
        cr.total_return_amount
    FROM 
        CustomerReturnStats cr
    JOIN 
        customer c ON cr.c_customer_sk = c.c_customer_sk
    WHERE 
        cr.rnk <= 5
),

HighValueReturns AS (
    SELECT 
        c.c_customer_sk,
        SUM(sr_return_amt_inc_tax) AS high_value_return_amount
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        sr_return_amt_inc_tax > 100.00
    GROUP BY 
        c.c_customer_sk
)

SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    COALESCE(t.total_returns, 0) AS total_returns,
    COALESCE(t.total_return_amount, 0) AS total_return_amount,
    COALESCE(hv.high_value_return_amount, 0) AS high_value_return_amount,
    CONCAT(t.c_first_name, ' ', t.c_last_name) AS full_customer_name,
    CASE 
        WHEN t.total_return_amount > 500 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    TopReturningCustomers t
LEFT JOIN 
    HighValueReturns hv ON t.c_customer_sk = hv.c_customer_sk
ORDER BY 
    t.total_return_amount DESC;
