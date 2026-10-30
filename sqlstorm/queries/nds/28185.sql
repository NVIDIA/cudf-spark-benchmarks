
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Has dependents'
            ELSE 'No dependents'
        END AS dependent_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.dependent_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    total_orders,
    dependent_status,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
FROM 
    combined_data
WHERE 
    total_sales > 0
ORDER BY 
    total_sales DESC, 
    full_name ASC
LIMIT 100;
