
WITH Address_Info AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS normalized_location
    FROM 
        customer_address 
),
Customer_Gender AS (
    SELECT 
        cd_demo_sk,
        cd_gender
    FROM 
        customer_demographics
),
Customer_Info AS (
    SELECT 
        c_customer_sk, 
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender
    FROM 
        customer 
    JOIN 
        Customer_Gender ON c_current_cdemo_sk = cd_demo_sk
),
Date_Info AS (
    SELECT 
        d_date_sk,
        d_month_seq,
        d_year,
        d_day_name
    FROM 
        date_dim
    WHERE 
        d_year = 2023
),
Sales_Info AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ai.full_address,
    ci.full_name,
    ci.cd_gender,
    di.d_day_name,
    di.d_month_seq,
    di.d_year,
    si.total_sales,
    si.total_orders
FROM 
    Address_Info ai
JOIN 
    Customer_Info ci ON ai.ca_address_sk = ci.c_customer_sk
JOIN 
    Date_Info di ON di.d_date_sk = (SELECT MAX(d_date_sk) FROM Date_Info)
JOIN 
    Sales_Info si ON si.ws_item_sk = ci.c_customer_sk
ORDER BY 
    si.total_sales DESC;
