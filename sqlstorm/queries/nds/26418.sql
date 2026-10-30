
WITH AddressData AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS formatted_address,
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
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate, 
        cd_credit_rating, 
        cd_dep_count,
        CONCAT(c_login, '@example.com') AS email
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name, 
    cd.email, 
    ad.formatted_address, 
    ad.ca_city, 
    ad.ca_state, 
    ad.ca_zip, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    CustomerData cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressData ad ON ca.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_sales DESC, 
    cd.full_name;
