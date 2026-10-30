
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name)) AS address_length
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_info AS (
    SELECT 
        d_date_sk,
        d_date,
        d_month_seq,
        d_year,
        d_day_name,
        d_quarter_name
    FROM 
        date_dim
    WHERE 
        d_year >= 2020
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws_bill_customer_sk,
        ws.ws_sold_date_sk
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs_bill_customer_sk,
        cs.cs_sold_date_sk
    FROM 
        catalog_sales cs
)
SELECT 
    pi.full_name,
    sa.full_address,
    di.d_date,
    sd.ws_sales_price,
    sd.ws_quantity,
    sd.ws_sales_price * sd.ws_quantity AS total_sales,
    COUNT(sd.ws_order_number) AS order_count,
    AVG(LENGTH(pi.full_name)) AS average_name_length,
    SUM(sa.address_length) AS total_address_length
FROM 
    customer_info pi
JOIN 
    processed_addresses sa ON pi.c_customer_sk = sa.ca_address_sk
JOIN 
    sales_data sd ON pi.c_customer_sk = sd.ws_bill_customer_sk
JOIN 
    date_info di ON sd.ws_sold_date_sk = di.d_date_sk
GROUP BY 
    pi.full_name, sa.full_address, di.d_date, sd.ws_sales_price, sd.ws_quantity
ORDER BY 
    total_sales DESC;
