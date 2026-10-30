
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
CustomerAddresses AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cd.gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_year = 2023
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
SalesCustomerDetails AS (
    SELECT 
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales
    FROM 
        CustomerAddresses ca
    LEFT JOIN 
        SalesData sd ON ca.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    sc.c_first_name AS first_name,
    sc.c_last_name AS last_name,
    sc.total_sales,
    ad.ca_city,
    ad.ca_state,
    dd.d_day_name
FROM 
    SalesCustomerDetails sc
JOIN 
    AddressDetails ad ON sc.c_customer_sk = ad.ca_address_sk
JOIN 
    DateDetails dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
WHERE 
    sc.total_sales > 1000
ORDER BY 
    sc.total_sales DESC
LIMIT 100;
