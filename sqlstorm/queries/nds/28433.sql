
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city AS city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        CASE 
            WHEN LENGTH(c.c_first_name) >= 5 THEN 'First Name Long' 
            ELSE 'First Name Short' 
        END AS first_name_length_category
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_country = 'USA'
),
AggregatedDetails AS (
    SELECT 
        cd.city,
        COUNT(*) AS customer_count,
        AVG(name_length) AS avg_name_length,
        COUNT(DISTINCT cd.full_name) AS distinct_names
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.city
)
SELECT 
    ad.city,
    ad.customer_count,
    ad.avg_name_length,
    ad.distinct_names,
    RANK() OVER (ORDER BY ad.customer_count DESC) AS city_rank
FROM 
    AggregatedDetails ad
WHERE 
    ad.customer_count > 10
ORDER BY 
    ad.customer_count DESC;
