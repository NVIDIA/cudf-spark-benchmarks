
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
                    CASE 
                        WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number)
                        ELSE ''
                    END)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts AS ad ON c.c_current_addr_sk = ad.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    sd.total_quantity,
    sd.total_spent,
    COUNT(DISTINCT ci.ca_city) AS unique_cities,
    CONCAT(ci.ca_country, ' (', ci.ca_state, ')') AS location_info
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    SalesData AS sd ON ci.c_customer_sk = sd.customer_sk
WHERE 
    (sd.total_spent IS NULL OR sd.total_spent > 100) 
GROUP BY 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    sd.total_quantity,
    sd.total_spent,
    ci.ca_country,
    ci.ca_state
ORDER BY 
    sd.total_spent DESC 
LIMIT 10;
