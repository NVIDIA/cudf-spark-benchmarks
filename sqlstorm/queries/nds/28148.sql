
WITH Address_Concat AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number, ca_city, ca_state, ca_zip, ca_country) AS full_address
    FROM 
        customer_address
),
Customer_Concat AS (
    SELECT 
        c_customer_sk,
        CONCAT_WS(' ', c_first_name, c_last_name) AS full_name
    FROM 
        customer
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.full_address,
        cc.full_name
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Concat ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        Customer_Concat cc ON c.c_customer_sk = cc.c_customer_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_credit_rating,
    COUNT(*) AS count_customers
FROM 
    Demographics d
GROUP BY 
    d.cd_gender, d.cd_marital_status, d.cd_credit_rating
HAVING 
    COUNT(*) > 10
ORDER BY 
    count_customers DESC;
