
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        LOWER(TRIM(ca_city)) AS normalized_city,
        TRIM(ca_state) AS state,
        ca_zip AS zip_code,
        CONCAT(LOWER(TRIM(ca_country)), '/', TRIM(ca_state)) AS country_state
    FROM 
        customer_address
),
gender_distribution AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
),
top_cities AS (
    SELECT 
        normalized_city, 
        COUNT(*) AS city_count
    FROM 
        processed_addresses
    GROUP BY 
        normalized_city
    ORDER BY 
        city_count DESC
    LIMIT 10
),
sales_per_country AS (
    SELECT 
        full_address,
        COUNT(ws_order_number) AS total_sales
    FROM 
        processed_addresses AS addresses
    JOIN 
        web_sales AS sales ON addresses.ca_address_sk = sales.ws_ship_addr_sk
    GROUP BY 
        full_address
    ORDER BY 
        total_sales DESC
    LIMIT 10
)

SELECT 
    g.cd_gender,
    g.gender_count,
    c.normalized_city,
    c.city_count,
    s.full_address,
    s.total_sales
FROM 
    gender_distribution AS g
CROSS JOIN 
    top_cities AS c
CROSS JOIN 
    sales_per_country AS s
ORDER BY 
    g.cd_gender, c.city_count DESC, s.total_sales DESC;
