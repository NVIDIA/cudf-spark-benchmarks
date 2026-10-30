
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependent_count,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
high_value_customers AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        items.total_sold,
        items.total_revenue,
        CASE 
            WHEN items.total_revenue > 10000 THEN 'High Value'
            ELSE 'Standard'
        END AS customer_segment
    FROM 
        customer_info ci
    JOIN 
        item_sales items ON ci.c_customer_sk = items.ws_item_sk
)
SELECT 
    customer_segment,
    COUNT(DISTINCT full_name) AS customer_count,
    AVG(total_revenue) AS avg_revenue,
    SUM(total_sold) AS total_items_sold
FROM 
    high_value_customers
GROUP BY 
    customer_segment
ORDER BY 
    customer_count DESC;
