
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COALESCE(MAX(ws.ws_sold_date_sk), 0) AS last_purchase_date_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        cs.*,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.order_count > 5
),
customer_address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        s.s_store_name
    FROM 
        customer_address ca
    JOIN 
        store s ON s.s_store_sk = 1  
    WHERE 
        ca.ca_state = 'CA' OR ca.ca_country = 'USA'
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.total_sales,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_address_info ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE 
    hvc.sales_rank <= 100
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
