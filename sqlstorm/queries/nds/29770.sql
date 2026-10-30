
WITH detailed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_date AS registration_date,
        d.d_month_seq,
        d.d_year,
        da.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    JOIN 
        detailed_addresses da ON c.c_current_addr_sk = da.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.c_first_name,
        ci.c_last_name,
        ci.full_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.registration_date
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
),
aggregated_sales AS (
    SELECT 
        full_address,
        cd_gender,
        cd_marital_status,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        sales_info
    GROUP BY 
        full_address, cd_gender, cd_marital_status
)
SELECT 
    full_address,
    cd_gender,
    cd_marital_status,
    total_sales,
    total_revenue,
    avg_sales_price
FROM 
    aggregated_sales
WHERE 
    total_sales > 5
ORDER BY 
    total_revenue DESC, total_sales DESC;
