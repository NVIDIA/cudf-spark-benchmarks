
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
),
CombinedData AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ac.cd_gender,
        ac.cd_marital_status,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(ss.avg_sales_price, 0) AS avg_sales_price
    FROM 
        ActiveCustomers ac
    LEFT JOIN 
        CustomerReturns cr ON ac.c_customer_sk = cr.customer_sk
    LEFT JOIN 
        SalesSummary ss ON ac.c_customer_sk = ss.customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.return_count,
    c.total_return_amount,
    c.total_sales,
    c.order_count,
    c.avg_sales_price,
    CASE 
        WHEN c.return_count > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CombinedData c
WHERE 
    c.return_count + c.order_count > 5
ORDER BY 
    c.total_sales DESC
LIMIT 50;
