
WITH detailed_customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state, ca.ca_zip, 
        c.c_salutation, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
        cd.cd_purchase_estimate, cd.cd_credit_rating, 
        cd.cd_dep_count, cd.cd_dep_employed_count, cd.cd_dep_college_count
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_zip,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    cd_dep_count,
    cd_dep_employed_count,
    cd_dep_college_count,
    total_net_profit,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Value Customer'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    detailed_customer_info
WHERE 
    (cd_gender = 'F' AND cd_marital_status = 'M') OR 
    (cd_gender = 'M' AND cd_marital_status = 'S')
ORDER BY 
    total_net_profit DESC
LIMIT 100;
