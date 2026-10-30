
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
        cr.sr_customer_sk,
        cr.total_return_amt,
        cr.total_returns,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amt DESC) AS rn
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_return_amt > 1000
), 
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_bill_customer_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    COALESCE(tc.total_returns, 0) AS total_returns,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) > 0 THEN (COALESCE(tc.total_return_amt, 0) / COALESCE(ss.total_sales, 0)) * 100
        ELSE 0 
    END AS return_percentage
FROM 
    customer c
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.sr_customer_sk
LEFT JOIN 
    SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    c.c_birth_month = 12 
    AND c.c_birth_day <= 25
ORDER BY 
    return_percentage DESC
LIMIT 10;
