
WITH AddressCity AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_city) AS city_upper
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(LOWER(c.c_first_name), ' ', UPPER(c.c_last_name), ' - ', cd.cd_gender) AS customer_full_info,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CityGrouped AS (
    SELECT 
        city_lower,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CAST(ca_address_sk AS STRING), ', ') AS address_sk_list
    FROM 
        AddressCity
    GROUP BY 
        city_lower
)
SELECT 
    ci.customer_full_info,
    ci.cd_marital_status,
    ci.cd_education_status,
    cg.address_count,
    cg.address_sk_list
FROM 
    CustomerInfo ci
LEFT JOIN 
    CityGrouped cg ON ci.customer_full_info LIKE '%' || cg.city_lower || '%'
ORDER BY 
    ci.customer_full_info;
