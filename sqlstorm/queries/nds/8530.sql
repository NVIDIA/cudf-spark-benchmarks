WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_returned_date_sk BETWEEN 2458837 AND 2459199 
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458837 AND 2459199 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    CD.c_customer_sk,
    SUM(COALESCE(CR.total_returned_quantity, 0)) AS total_returned_quantity,
    SUM(SA.total_sales) AS total_sales,
    CD.cd_gender,
    CD.cd_marital_status,
    CD.cd_education_status,
    CD.cd_purchase_estimate,
    CD.cd_credit_rating,
    CD.cd_dep_count,
    CD.cd_dep_employed_count
FROM 
    CustomerDemographics CD
LEFT JOIN 
    CustomerReturns CR ON CD.c_customer_sk = CR.cr_returning_customer_sk
LEFT JOIN 
    SalesSummary SA ON CD.c_customer_sk = SA.customer_sk
GROUP BY 
    CD.c_customer_sk, 
    CD.cd_gender, 
    CD.cd_marital_status, 
    CD.cd_education_status, 
    CD.cd_purchase_estimate, 
    CD.cd_credit_rating, 
    CD.cd_dep_count, 
    CD.cd_dep_employed_count
ORDER BY 
    total_sales DESC, 
    total_returned_quantity DESC
LIMIT 100;