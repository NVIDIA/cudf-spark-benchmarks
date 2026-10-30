
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
spending_bracket AS (
    SELECT
        CASE 
            WHEN total_spent < 100 THEN 'Low' 
            WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium' 
            ELSE 'High' 
        END AS spending_category,
        COUNT(*) AS customer_count
    FROM 
        customer_data
    GROUP BY 
        spending_category
)
SELECT 
    sb.spending_category,
    sb.customer_count,
    ROUND((sb.customer_count * 100.0 / SUM(sb.customer_count) OVER ()), 2) AS percentage_of_total
FROM 
    spending_bracket sb
ORDER BY 
    sb.spending_category;
