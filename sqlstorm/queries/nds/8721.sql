WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_value,
        MAX(ws.ws_sales_price) AS max_sales_value,
        MIN(ws.ws_sales_price) AS min_sales_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459582 AND 2459588 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.order_count,
    ss.avg_sales_value,
    ss.max_sales_value,
    ss.min_sales_value,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    a.ca_city,
    a.ca_state
FROM 
    sales_summary ss
JOIN 
    demographics d ON ss.c_customer_sk = d.cd_demo_sk
JOIN 
    address_info a ON ss.c_customer_sk = a.ca_address_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC
LIMIT 100;