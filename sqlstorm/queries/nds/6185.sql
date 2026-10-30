
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.cd_demo_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        CustomerReturns cr ON cd.cd_demo_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesData sd ON cd.cd_demo_sk = sd.ws_bill_customer_sk
)
SELECT 
    cd.cd_demo_sk,
    SUM(cd.total_returns) AS total_returns,
    SUM(cd.total_return_amount) AS total_return_amount,
    SUM(cd.total_sales) AS total_sales,
    AVG(cd.total_sales) / NULLIF(SUM(cd.total_returns), 0) AS avg_sales_per_return
FROM 
    CombinedData cd
GROUP BY 
    cd.cd_demo_sk
HAVING 
    SUM(cd.total_sales) > 0
ORDER BY 
    avg_sales_per_return DESC
LIMIT 10;
