
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state, ca.ca_country
),
sales_summary AS (
    SELECT 
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_paid) AS total_spent,
        COUNT(cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.total_orders,
    ci.profitable_orders,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(ss.total_spent, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(ss.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.cs_bill_customer_sk
ORDER BY 
    total_spent DESC, full_name;
