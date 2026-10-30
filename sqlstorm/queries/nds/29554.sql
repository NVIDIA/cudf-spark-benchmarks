
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_birth_month,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ps.total_sales,
        ps.total_orders,
        RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM 
        customer_info ci
    JOIN 
        purchase_summary ps ON ci.c_customer_sk = ps.c_customer_sk
    WHERE 
        ci.rank = 1
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.ca_city,
    c.ca_state,
    c.total_sales,
    c.total_orders,
    c.sales_rank
FROM 
    ranked_customers c
WHERE 
    c.sales_rank <= 100
ORDER BY 
    c.total_sales DESC;
