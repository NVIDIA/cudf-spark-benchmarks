
WITH address_components AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number) || ' ' || TRIM(ca_street_name) || ' ' || TRIM(ca_street_type) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip_code,
        TRIM(ca_country) AS country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education_status,
        CONCAT(a.full_address, ', ', a.city, ', ', a.state, ' ', a.zip_code, ', ', a.country) AS complete_contact_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_components a ON c.c_current_addr_sk = a.ca_address_sk
),
active_customers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        COUNT(DISTINCT w.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CAST(w.ws_web_page_sk AS STRING), ', ') AS accessed_web_pages
    FROM 
        web_sales w
    JOIN 
        customer_info c ON w.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    ac.order_count,
    ac.accessed_web_pages
FROM 
    customer_info ci
JOIN 
    active_customers ac ON ci.c_customer_sk = ac.customer_sk
WHERE 
    ci.gender = 'F'
    AND ac.order_count > 5
ORDER BY 
    ci.full_name;
