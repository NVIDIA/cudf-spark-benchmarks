
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
demographics_analysis AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(si.total_sales, 0) AS total_sales,
        COALESCE(si.order_count, 0) AS order_count,
        RANK() OVER (ORDER BY COALESCE(si.total_sales, 0) DESC) AS sales_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_ship_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    total_sales,
    order_count,
    sales_rank,
    CASE 
        WHEN sales_rank <= 10 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    demographics_analysis
WHERE 
    ca_state IN ('NY', 'CA', 'TX')
ORDER BY 
    sales_rank;
