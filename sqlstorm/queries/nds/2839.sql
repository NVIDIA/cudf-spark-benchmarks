
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(sr_ticket_number) AS total_return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales_value,
        COUNT(ws_order_number) AS total_sales_count,
        AVG(ws_sales_price) AS average_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ws.total_sales_value, 0) AS total_sales_value,
        COALESCE(ws.total_sales_count, 0) AS total_sales_count,
        CASE 
            WHEN COALESCE(ws.total_sales_value, 0) > 0 
            THEN COALESCE(cr.total_returned_amount, 0) / ws.total_sales_value 
            ELSE NULL 
        END AS return_rate
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned_quantity,
    tc.total_returned_amount,
    tc.total_sales_value,
    tc.total_sales_count,
    ROUND(tc.return_rate * 100, 2) AS return_rate_percentage,
    CASE 
        WHEN tc.total_sales_value > 10000 THEN 'High Value'
        WHEN tc.total_sales_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    TopCustomers tc
WHERE 
    tc.return_rate > 0.1 OR tc.total_sales_count > 50
ORDER BY 
    return_rate_percentage DESC NULLS LAST
LIMIT 100;
