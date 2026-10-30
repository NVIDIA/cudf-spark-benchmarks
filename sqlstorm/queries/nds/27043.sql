
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
purchase_summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.full_name, ci.ca_city, ci.ca_state
),
gender_statistics AS (
    SELECT 
        ci.cd_gender,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        SUM(ps.total_spent) AS total_spent,
        AVG(ps.total_spent) AS avg_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        purchase_summary ps ON ci.full_name = ps.full_name
    GROUP BY 
        ci.cd_gender
)
SELECT 
    gs.cd_gender,
    gs.customer_count,
    gs.total_spent,
    gs.avg_spent,
    RANK() OVER (ORDER BY gs.total_spent DESC) AS spending_rank
FROM 
    gender_statistics gs
ORDER BY 
    spending_rank;
