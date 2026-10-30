
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        TRIM(ca_city) AS cleaned_city,
        CONCAT(UPPER(LEFT(ca_state, 1)), LOWER(SUBSTRING(ca_state, 2))) AS formatted_state,
        REPLACE(ca_zip, '-', '') AS sanitized_zip
    FROM 
        customer_address
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        a.cleaned_city,
        a.formatted_state,
        a.sanitized_zip
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        processed_addresses a ON c.c_current_addr_sk = a.ca_address_sk
), 
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    s.total_sales,
    s.order_count,
    c.cleaned_city,
    c.formatted_state,
    c.sanitized_zip
FROM 
    customer_info c
LEFT JOIN 
    sales_summary s ON c.c_customer_sk = s.cs_item_sk
WHERE 
    c.cleaned_city LIKE '%York%' 
    AND c.formatted_state = 'Ny'
ORDER BY 
    s.total_sales DESC
LIMIT 100;
