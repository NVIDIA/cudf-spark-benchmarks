
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ', 
            TRIM(ca_street_name), ' ',
            TRIM(ca_street_type), 
            COALESCE(CONCAT(' Suite ', TRIM(ca_suite_number)), '')
        ) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        addr.full_address,
        addr.ca_city,
        addr.ca_state,
        addr.ca_zip,
        addr.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts addr ON c.c_current_addr_sk = addr.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.full_address,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    cd.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales_value
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.customer_sk
WHERE 
    cd.ca_state = 'CA'
ORDER BY 
    total_sales_value DESC
LIMIT 50;
