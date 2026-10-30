
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
gender_sales AS (
    SELECT
        ci.full_name,
        ci.cd_gender,
        ci.ca_city,
        ci.ca_state,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cd_gender,
    COUNT(*) AS customer_count,
    SUM(total_quantity) AS total_quantity,
    SUM(total_net_profit) AS total_net_profit,
    AVG(total_net_profit) AS average_profit
FROM 
    gender_sales
WHERE 
    ca_city ILIKE '%New%' 
GROUP BY 
    cd_gender
ORDER BY 
    customer_count DESC;
