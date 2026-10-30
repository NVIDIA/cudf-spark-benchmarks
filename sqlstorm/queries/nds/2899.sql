
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AverageReturns AS (
    SELECT 
        cr_returning_customer_sk,
        AVG(total_returned_quantity) AS avg_returned_quantity,
        AVG(total_return_amount) AS avg_return_amount
    FROM 
        CustomerReturns 
    GROUP BY 
        cr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.total_sales,
        ar.avg_returned_quantity,
        ar.avg_return_amount
    FROM 
        customer c
    JOIN 
        WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        AverageReturns ar ON c.c_customer_sk = ar.cr_returning_customer_sk
    WHERE 
        ws.total_sales > 1000 
        AND ar.avg_returned_quantity < 5
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.avg_returned_quantity,
    hvc.avg_return_amount,
    COALESCE(NULLIF(hvc.avg_return_amount, 0), 1) AS adjusted_return_amount,
    CASE 
        WHEN hvc.avg_returned_quantity IS NULL THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_sales DESC
LIMIT 10 OFFSET 0;
