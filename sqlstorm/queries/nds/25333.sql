
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, ' ', CASE WHEN cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END) AS demo_group
    FROM 
        customer_demographics
),
FullCustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address,
        d.demo_group,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        AddressComponents a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    fd.full_name,
    fd.full_address,
    fd.demo_group,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    FullCustomerData fd
LEFT JOIN 
    web_sales ws ON fd.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    fd.cd_purchase_estimate > 1000
GROUP BY 
    fd.full_name, fd.full_address, fd.demo_group
ORDER BY 
    total_spent DESC
LIMIT 10;
