
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type) AS full_address,
        LOWER(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS normalized_city_state_zip
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        pa.full_address,
        pa.normalized_city_state_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    si.total_sales,
    si.last_purchase_date,
    CONCAT('City: ', LEFT(ci.normalized_city_state_zip, POSITION(',' IN ci.normalized_city_state_zip) - 1),
           ', State: ', SUBSTRING(ci.normalized_city_state_zip, POSITION(',' IN ci.normalized_city_state_zip) + 2, 2),
           ', Zip: ', RIGHT(ci.normalized_city_state_zip, LENGTH(ci.normalized_city_state_zip) - POSITION(' ' IN ci.normalized_city_state_zip))) AS formatted_city_state_zip
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    si.total_sales > 1000
ORDER BY 
    si.total_sales DESC;
