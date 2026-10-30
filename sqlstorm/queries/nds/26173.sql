
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        REGEXP_REPLACE(ca_street_name, '[^a-zA-Z0-9 ]', '') AS clean_street_name,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_state) AS lower_state,
        SUBSTRING(ca_zip FROM 1 FOR 5) AS zip_prefix
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.clean_street_name,
        a.upper_city,
        a.lower_state,
        a.zip_prefix,
        d.gender_marital_status,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.order_count, 0) AS order_count
    FROM 
        customer c
    JOIN 
        AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    clean_street_name AS street_name,
    upper_city AS city,
    lower_state AS state,
    zip_prefix AS zip_code,
    gender_marital_status AS gender_and_marital,
    total_sales AS total_spent,
    order_count AS orders_made
FROM 
    CombinedData
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
