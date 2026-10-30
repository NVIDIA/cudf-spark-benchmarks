
WITH CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
WebSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    wd.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate
FROM 
    CustomerAddress ca
JOIN 
    WebSales wd ON ca.ca_address_sk = wd.ws_bill_customer_sk
JOIN 
    customer c ON wd.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA'
    AND cd.cd_marital_status = 'M'
ORDER BY 
    wd.total_sales DESC;
