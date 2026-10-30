
WITH address_data AS (
    SELECT
        CONCAT(COALESCE(ca_street_number, ''), ' ', COALESCE(ca_street_name, ''), ' ', COALESCE(ca_street_type, ''), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM customer_address
), 
demographics_data AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status, cd_education_status
),
sales_data AS (
    SELECT
        COUNT(*) AS sales_count,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price
    FROM web_sales
),
combined_data AS (
    SELECT
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        dem.cd_gender,
        dem.cd_marital_status,
        sales.sales_count,
        sales.total_sales,
        sales.avg_sales_price,
        sales.max_sales_price,
        sales.min_sales_price
    FROM address_data ad
    JOIN demographics_data dem ON ad.ca_city LIKE '%New%' AND ad.ca_state = 'NY' 
    CROSS JOIN sales_data sales
)
SELECT
    full_address,
    ca_city,
    ca_state,
    ca_country,
    cd_gender,
    cd_marital_status,
    sales_count,
    total_sales,
    avg_sales_price,
    max_sales_price,
    min_sales_price
FROM combined_data
ORDER BY total_sales DESC, sales_count DESC;
