
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
processed_contacts AS (
    SELECT 
        full_name,
        REPLACE(LOWER(full_name), ' ', '_') AS file_name,
        CONCAT('mail@', LOWER(REPLACE(full_name, ' ', '.')), '.com') AS email
    FROM 
        ranked_customers
    WHERE 
        gender_rank <= 50
),
customer_summary AS (
    SELECT 
        pc.file_name,
        pc.email,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        processed_contacts pc
    JOIN 
        web_sales ws ON pc.file_name LIKE CONCAT('%', ws.ws_bill_customer_sk, '%')
    GROUP BY 
        pc.file_name, pc.email
)
SELECT 
    cs.file_name,
    cs.email,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer_summary cs
ORDER BY 
    cs.total_spent DESC;
