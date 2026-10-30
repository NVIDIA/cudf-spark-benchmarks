
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ReturnData AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_customer_sk
),
SalesPerCustomer AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (cd.total_sales - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM 
        CustomerData AS cd
    LEFT JOIN 
        ReturnData AS rd ON cd.c_customer_sk = rd.sr_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.total_sales,
    c.total_returns,
    c.net_sales,
    CASE 
        WHEN c.net_sales > 10000 THEN 'High Value'
        WHEN c.net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    SalesPerCustomer AS c
ORDER BY 
    c.net_sales DESC
LIMIT 100;
