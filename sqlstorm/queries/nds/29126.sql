
WITH Address_Components AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
), 
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ac.full_address,
        ac.ca_city,
        ac.ca_state,
        ac.ca_zip,
        ac.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ac.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        Address_Components ac ON c.c_current_addr_sk = ac.ca_address_sk
)
SELECT 
    full_name, 
    cd_gender, 
    cd_marital_status, 
    cd_purchase_estimate, 
    full_address, 
    ca_city, 
    ca_state, 
    ca_zip, 
    ca_country 
FROM 
    Customer_Stats
WHERE 
    rank_by_purchase <= 10
ORDER BY 
    ca_state, 
    cd_purchase_estimate DESC;
