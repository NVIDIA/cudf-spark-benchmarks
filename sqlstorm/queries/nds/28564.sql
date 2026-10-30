
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name, c.c_first_name) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address AS ca
),
GenderStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cu.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer AS cu
    JOIN 
        customer_demographics AS cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    rc.full_name,
    ca.full_address,
    gs.customer_count,
    gs.avg_purchase_estimate
FROM 
    RankedCustomers AS rc
LEFT JOIN 
    CustomerAddresses AS ca ON rc.c_customer_sk = ca.ca_address_sk
JOIN 
    GenderStats AS gs ON rc.cd_gender = gs.cd_gender
WHERE 
    rc.rn <= 10
ORDER BY 
    rc.cd_gender, rc.rn;
