WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        DENSE_RANK() OVER (ORDER BY COALESCE(cr.total_return_amt, 0) DESC) AS rnk
    FROM 
        customer AS c
    LEFT JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.sr_customer_sk
)

SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_quantity,
    tc.total_return_amt,
    CASE 
        WHEN tc.total_return_amt > 500 THEN 'High Value'
        WHEN tc.total_return_amt BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    TopCustomers AS tc
WHERE 
    tc.rnk <= 10
ORDER BY 
    tc.total_return_amt DESC;