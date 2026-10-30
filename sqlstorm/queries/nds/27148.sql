
WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_street_number, 
        ca.ca_street_name, 
        ca.ca_street_type, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer_demographics cd
),
CompleteCustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cad.full_address, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        CustomerAddressDetails cad ON c.c_current_addr_sk = cad.ca_address_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesRecords AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_net_paid) AS total_sales, 
        COUNT(ws.ws_order_number) AS order_count 
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerSalesInfo AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.full_address,
        ci.cd_gender,
        ci.cd_marital_status,
        COALESCE(sr.total_sales, 0) AS total_sales,
        COALESCE(sr.order_count, 0) AS order_count
    FROM 
        CompleteCustomerInfo ci
    LEFT JOIN 
        SalesRecords sr ON ci.c_customer_sk = sr.ws_bill_customer_sk
)
SELECT 
    csi.c_customer_sk, 
    csi.c_first_name, 
    csi.c_last_name, 
    csi.full_address, 
    csi.cd_gender, 
    csi.cd_marital_status, 
    csi.total_sales, 
    csi.order_count,
    CASE 
        WHEN csi.total_sales > 1000 THEN 'High Value'
        WHEN csi.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerSalesInfo csi
WHERE 
    csi.cd_gender = 'F'
ORDER BY 
    csi.total_sales DESC
LIMIT 100;
