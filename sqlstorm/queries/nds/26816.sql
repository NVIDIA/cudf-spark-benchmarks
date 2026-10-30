
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerAggregates AS (
    SELECT 
        full_name,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN LOWER(cd_education_status) LIKE '%graduate%' THEN 1 ELSE 0 END) AS graduate_count
    FROM 
        RankedCustomers
    GROUP BY 
        full_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(c.total_customers) AS total_customers,
    SUM(c.male_count) AS total_males,
    SUM(c.married_count) AS total_married,
    SUM(c.graduate_count) AS total_graduates
FROM 
    CustomerAggregates AS c
INNER JOIN 
    customer_address AS ca ON c.full_name = ca.ca_city AND c.full_name = ca.ca_state
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_customers DESC
LIMIT 10;
