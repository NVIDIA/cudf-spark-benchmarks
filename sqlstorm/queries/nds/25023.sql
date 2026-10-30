
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_country) AS country_lower
    FROM 
        customer_address
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender AS gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status,
        LENGTH(cd_education_status) AS education_length
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    ad.full_address,
    cd.gender,
    cd.marital_status,
    cd.education_length,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    customer c
JOIN 
    AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    SalesDetails sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ad.city_upper LIKE 'NEW%' 
GROUP BY 
    c.c_customer_id,
    ad.full_address,
    cd.gender,
    cd.marital_status,
    cd.education_length,
    sd.total_sales,
    sd.order_count
ORDER BY 
    total_sales DESC, c.c_customer_id;
