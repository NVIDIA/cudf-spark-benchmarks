
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        TRIM(c_first_name) AS first_name,
        TRIM(c_last_name) AS last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ca.*,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressData ca ON c.c_current_addr_sk = ca.ca_address_sk
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
IncomeLevel AS (
    SELECT 
        hd_demo_sk,
        CASE 
            WHEN hd_income_band_sk = 1 THEN 'Low'
            WHEN hd_income_band_sk = 2 THEN 'Medium'
            WHEN hd_income_band_sk = 3 THEN 'High'
        END AS income_band
    FROM 
        household_demographics
)
SELECT 
    c.full_name,
    c.full_address,
    c.ca_city,
    c.ca_state,
    c.ca_zip,
    c.ca_country,
    c.cd_gender,
    c.cd_marital_status,
    COALESCE(sd.total_sales, 0) AS total_web_sales,
    il.income_band
FROM 
    CustomerData c
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN 
    IncomeLevel il ON c.c_customer_sk = il.hd_demo_sk
WHERE 
    c.cd_purchase_estimate > 0
ORDER BY 
    total_web_sales DESC
LIMIT 100;
