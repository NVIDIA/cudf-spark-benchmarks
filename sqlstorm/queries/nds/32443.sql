
WITH RecursiveSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS demo_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
),
AggSalesReturns AS (
    SELECT 
        s.customer_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
        CASE 
            WHEN s.total_sales > 1000 THEN 'High Value'
            WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM 
        RecursiveSales s
    LEFT JOIN 
        SalesReturns r ON s.customer_sk = r.sr_customer_sk
)
SELECT 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status,
    a.total_sales,
    a.total_returns,
    a.total_returned_amt,
    a.sales_category,
    ROW_NUMBER() OVER (PARTITION BY cd.ca_state ORDER BY a.total_sales DESC) AS state_sales_rank
FROM 
    AggSalesReturns a
JOIN 
    CustomerDemographics cd ON a.customer_sk = cd.c_customer_sk
WHERE 
    cd.demo_rank = 1
ORDER BY 
    a.total_sales DESC, 
    cd.ca_state
LIMIT 100;
