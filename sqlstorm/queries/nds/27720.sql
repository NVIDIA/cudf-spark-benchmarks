
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY c.c_customer_sk) AS rn
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), aggregated_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    r.c_first_name, 
    r.c_last_name, 
    r.ca_city, 
    r.cd_gender, 
    r.cd_marital_status, 
    r.cd_education_status, 
    COALESCE(a.total_sales, 0) AS total_sales,
    COALESCE(a.order_count, 0) AS order_count
FROM 
    ranked_customers r
LEFT JOIN 
    aggregated_sales a ON r.c_customer_sk = a.ws_bill_customer_sk
WHERE 
    r.rn <= 5
ORDER BY 
    r.ca_city, 
    total_sales DESC;
