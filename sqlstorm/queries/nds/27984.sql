
WITH CustomerInfo AS (
    SELECT 
        C.c_customer_id,
        CONCAT(C.c_first_name, ' ', C.c_last_name) AS full_name,
        CA.ca_city,
        CD.cd_gender,
        CASE 
            WHEN CD.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        CD.cd_purchase_estimate,
        CD.cd_credit_rating,
        ROW_NUMBER() OVER(PARTITION BY CA.ca_city ORDER BY CD.cd_purchase_estimate DESC) AS rank
    FROM 
        customer C
    JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
),
TopCustomers AS (
    SELECT 
        c_customer_id, 
        full_name, 
        ca_city, 
        marital_status, 
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        CustomerInfo
    WHERE 
        rank <= 10
)
SELECT 
    ca_city,
    COUNT(*) AS number_of_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd_purchase_estimate) AS max_purchase_estimate,
    MIN(cd_purchase_estimate) AS min_purchase_estimate
FROM 
    TopCustomers
GROUP BY 
    ca_city
ORDER BY 
    number_of_customers DESC;
