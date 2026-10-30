
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        d.d_day_name
    FROM 
        date_dim d
    WHERE 
        d.d_year >= 2020
),
sales_info AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, 
        ws.ws_ship_customer_sk
),
combined_info AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        si.total_sales,
        si.order_count,
        di.d_year,
        di.d_month_seq,
        di.d_week_seq,
        di.d_day_name
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_ship_customer_sk
    JOIN 
        date_info di ON si.ws_ship_date_sk = di.d_date_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    order_count,
    d_year,
    d_month_seq,
    d_week_seq,
    d_day_name
FROM 
    combined_info
WHERE 
    cd_gender = 'F' AND
    total_sales > 10000
ORDER BY 
    total_sales DESC, 
    full_name;
