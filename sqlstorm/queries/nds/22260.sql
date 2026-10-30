
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND sr_returned_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
),
EligibleCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND cd.cd_dep_count > 0
        AND (COALESCE(cr.total_return_amt, 0) < 100 OR cr.total_returns IS NULL)
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ec.c_first_name,
    ec.c_last_name,
    sd.total_sales,
    sd.order_count,
    ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank,
    CASE 
        WHEN sd.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    CASE 
        WHEN ec.total_return_amt > 0 THEN 'High Return Customer'
        ELSE 'Low Return Customer'
    END AS return_status
FROM 
    EligibleCustomers ec
LEFT JOIN 
    SalesData sd ON ec.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ec.total_returns > 0 
    OR sd.total_sales IS NOT NULL 
ORDER BY 
    ec.c_first_name, ec.c_last_name;
