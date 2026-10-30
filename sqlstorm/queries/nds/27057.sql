
SELECT 
    UPPER(CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name)) AS full_customer_name,
    LOWER(c.c_email_address) AS email_in_lowercase,
    REPLACE(ca.ca_street_name, 'St', 'Street') AS corrected_street_name,
    CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_full,
    CONCAT('Income Band ', ib.ib_income_band_sk) AS income_band_description,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
JOIN 
    income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    c.c_birth_month = 1 AND c.c_birth_day = 1
GROUP BY 
    c.c_salutation, c.c_first_name, c.c_last_name, c.c_email_address, 
    ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip, 
    cd.cd_gender, ib.ib_income_band_sk
ORDER BY 
    total_orders DESC, full_customer_name;
