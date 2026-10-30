
WITH address_parts AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(' ', ca_street_number, ca_suite_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
),
demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics
),
sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        s.total_sales,
        s.total_orders
    FROM 
        customer c
    JOIN 
        demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        address_parts a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        sales s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    full_address,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(total_orders) AS max_orders,
    MIN(total_sales) AS min_sales,
    cd_gender,
    cd_marital_status,
    cd_education_status
FROM 
    combined
GROUP BY 
    full_address, cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    customer_count DESC, avg_sales DESC;
