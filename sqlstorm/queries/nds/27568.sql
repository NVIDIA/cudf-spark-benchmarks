
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(TRIM(ca_street_name)) AS processed_street_name,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_type)) AS full_address,
        CONCAT(TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip)) AS city_state_zip
    FROM 
        customer_address
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        da.processed_street_name,
        da.full_address,
        da.city_state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.processed_street_name,
    c.full_address,
    c.city_state_zip,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    customer_data c
LEFT JOIN 
    sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    c.cd_gender = 'F' AND c.cd_marital_status = 'M'
ORDER BY 
    c.c_last_name, c.c_first_name;
