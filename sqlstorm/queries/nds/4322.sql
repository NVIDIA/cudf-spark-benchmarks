
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns,
        AVG(sr_return_quantity) AS avg_return_quantity
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
        cr.total_return_amt,
        cr.total_returns,
        cr.avg_return_quantity,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_return_amt IS NOT NULL
),
HighReturnStates AS (
    SELECT 
        ca_state,
        SUM(cr.total_return_amt) AS state_return_amt
    FROM 
        customer_address ca
    JOIN 
        CustomerReturns cr ON ca.ca_address_sk = cr.sr_customer_sk
    GROUP BY 
        ca_state
    HAVING 
        SUM(cr.total_return_amt) > 1000
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_amt,
    tc.total_returns,
    tc.avg_return_quantity,
    hs.state_return_amt
FROM 
    TopCustomers tc
JOIN 
    HighReturnStates hs ON hs.state_return_amt = (
        SELECT MAX(state_return_amt) FROM HighReturnStates
    )
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_return_amt DESC;
