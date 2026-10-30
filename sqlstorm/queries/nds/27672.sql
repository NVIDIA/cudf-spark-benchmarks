
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.ca_city,
        c.ca_zip,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_education_status,
        c.cd_purchase_estimate
    FROM 
        customer_data c
    WHERE 
        c.purchase_rank <= 10
),
zip_analysis AS (
    SELECT 
        ca.ca_zip, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_zip
)
SELECT 
    t.c_customer_id,
    t.c_first_name,
    t.c_last_name,
    t.ca_city,
    t.ca_zip,
    t.cd_gender,
    t.cd_marital_status,
    z.customer_count,
    z.avg_purchase_estimate
FROM 
    top_customers t
JOIN 
    zip_analysis z ON t.ca_zip = z.ca_zip
ORDER BY 
    z.avg_purchase_estimate DESC, t.c_last_name, t.c_first_name;
