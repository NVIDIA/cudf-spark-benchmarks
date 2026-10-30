
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
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
        cr.total_returned_quantity,
        cr.total_returned_amt,
        cr.total_returns,
        DENSE_RANK() OVER (ORDER BY cr.total_returned_quantity DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cr.total_returned_quantity > 0
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(sd.total_spent, 0) AS total_spent,
    sd.order_count,
    tc.total_returned_quantity,
    tc.total_returned_amt,
    tc.total_returns
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesData sd ON tc.c_customer_sk = sd.customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.rank;
