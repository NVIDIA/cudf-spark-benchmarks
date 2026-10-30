
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city LIKE 'S%'
),
TopSpenders AS (
    SELECT 
        DISTINCT rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        RankedCustomers rc
    JOIN 
        CustomerAddresses ca ON rc.c_customer_sk = ca.ca_address_sk
    WHERE 
        rc.rank <= 10
)
SELECT 
    COUNT(*) AS total_top_spenders,
    COUNT(DISTINCT ts.ca_city) AS unique_cities,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    TopSpenders ts
JOIN 
    customer_demographics cd ON ts.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M'
    AND cd.cd_gender = 'F'
GROUP BY 
    cd.cd_purchase_estimate;
