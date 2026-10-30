WITH ranked_customers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_count AS (
    SELECT 
        ca.ca_city, 
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city
),
selected_customers AS (
    SELECT 
        rc.c_customer_id, 
        rc.c_first_name || ' ' || rc.c_last_name AS full_name, 
        rc.cd_gender, 
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rnk <= 5
)
SELECT 
    sc.full_name, 
    sc.cd_gender, 
    sc.cd_purchase_estimate, 
    ac.address_count
FROM 
    selected_customers sc
JOIN 
    address_count ac ON sc.cd_gender = 'M' 
ORDER BY 
    sc.cd_purchase_estimate DESC;