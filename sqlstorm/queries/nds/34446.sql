
WITH  SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CombinedData AS (
    SELECT 
        sd.customer_sk,
        sd.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        sd.order_count,
        cr.return_count,
        (sd.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        CustomerReturns cr ON sd.customer_sk = cr.customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.total_sales,
    cd.total_returns,
    cd.order_count,
    cd.return_count,
    cd.net_sales,
    ROW_NUMBER() OVER (ORDER BY cd.net_sales DESC) AS sales_rank
FROM 
    CombinedData cd
JOIN 
    customer c ON cd.customer_sk = c.c_customer_sk
WHERE 
    (cd.net_sales > 1000 AND cd.return_count < 3) 
    OR (cd.return_count IS NULL AND cd.order_count > 5)
ORDER BY 
    cd.net_sales DESC;
