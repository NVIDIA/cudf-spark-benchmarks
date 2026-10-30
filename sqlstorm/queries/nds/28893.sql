
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.order_count,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.cd_purchase_estimate
FROM 
    TopCustomers t
JOIN 
    AddressDetails a ON t.c_customer_sk = a.ca_address_sk
JOIN 
    CustomerDemographics d ON t.c_customer_sk = d.cd_demo_sk
WHERE 
    t.sales_rank <= 100
ORDER BY 
    t.total_sales DESC;
