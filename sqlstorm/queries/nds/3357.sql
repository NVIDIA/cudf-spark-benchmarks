
WITH SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_ext_sales_price) AS median_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_sales,
        ss.order_count,
        ss.median_sales
    FROM 
        customer cs
    JOIN 
        SalesStats ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalPerformance AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (tc.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales,
        tc.order_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        CustomerReturns cr ON tc.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    f.order_count,
    CASE 
        WHEN f.net_sales > 5000 THEN 'High-Value Customer'
        WHEN f.net_sales BETWEEN 2000 AND 5000 THEN 'Medium-Value Customer'
        ELSE 'Low-Value Customer'
    END AS customer_value_segment
FROM 
    FinalPerformance f
WHERE 
    f.net_sales IS NOT NULL
ORDER BY 
    f.net_sales DESC;
