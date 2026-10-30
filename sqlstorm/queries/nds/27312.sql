
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
), DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, ', ', cd_marital_status) AS demographic_info,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
), CustomerFullDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        dd.demographic_info,
        dd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
)
SELECT 
    cfd.full_name,
    cfd.c_email_address,
    cfd.full_address,
    cfd.ca_city,
    cfd.ca_state,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    CustomerFullDetails cfd
LEFT JOIN 
    web_sales ws ON cfd.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cfd.full_name, cfd.c_email_address, cfd.full_address, cfd.ca_city, cfd.ca_state
ORDER BY 
    total_spent DESC
LIMIT 10;
