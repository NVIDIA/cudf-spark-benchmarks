
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN TRIM(ca_suite_number) IS NOT NULL AND TRIM(ca_suite_number) != '' 
                    THEN CONCAT(' Suite ', TRIM(ca_suite_number)) 
                    ELSE '' END) AS full_address,
        LOWER(TRIM(ca_city)) AS city_lower,
        UPPER(TRIM(ca_state)) AS state_upper,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address
),
gender_demo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_desc
    FROM 
        customer_demographics
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    a.ca_address_sk,
    a.full_address,
    g.gender_desc,
    COALESCE(s.total_sales, 0) AS total_sales,
    s.transaction_count
FROM 
    processed_addresses a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    gender_demo g ON g.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    store_sales_summary s ON s.ss_store_sk = c.c_current_addr_sk
WHERE 
    a.city_lower LIKE '%town%' 
    AND a.state_upper = 'CA'
ORDER BY 
    total_sales DESC, 
    a.full_address;
