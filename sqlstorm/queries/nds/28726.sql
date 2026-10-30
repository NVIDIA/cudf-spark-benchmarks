
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        REPLACE(c.c_email_address, '@', '[at]') AS modified_email,
        SUBSTRING(c.c_birth_country, 1, 3) AS country_code
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_data AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        CONCAT(ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS city_state_zip
    FROM 
        customer_address ca
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_bill_customer_sk
),
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_date AS sales_date,
        d.d_day_name,
        d.d_month_seq
    FROM 
        date_dim d
)
SELECT 
    cd.full_name,
    cd.modified_email,
    ad.full_address,
    sd.total_sales,
    sd.order_count,
    di.sales_date,
    di.d_day_name,
    di.d_month_seq
FROM 
    customer_data cd
JOIN 
    address_data ad ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
JOIN 
    date_info di ON sd.ws_sold_date_sk = di.d_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
    AND sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC,
    cd.full_name ASC
LIMIT 50;
