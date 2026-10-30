
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressCount AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
FullCustomerData AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ac.address_count,
        ac.ca_city,
        ac.ca_state
    FROM 
        CustomerDetails cd
    JOIN 
        AddressCount ac ON cd.ca_city = ac.ca_city AND cd.ca_state = ac.ca_state
),
BenchmarkData AS (
    SELECT 
        *,
        CASE 
            WHEN address_count > 1000 THEN 'High Density'
            WHEN address_count BETWEEN 500 AND 1000 THEN 'Medium Density'
            ELSE 'Low Density'
        END AS density_category
    FROM 
        FullCustomerData
)
SELECT 
    density_category,
    COUNT(*) AS customer_volume,
    AVG(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_percentage,
    AVG(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_percentage,
    AVG(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_percentage,
    AVG(CASE WHEN cd_education_status LIKE '%College%' THEN 1 ELSE 0 END) AS college_educated_percentage
FROM 
    BenchmarkData
GROUP BY 
    density_category
ORDER BY 
    customer_volume DESC;
