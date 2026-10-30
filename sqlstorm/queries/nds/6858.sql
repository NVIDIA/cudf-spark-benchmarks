
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS average_order_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        ws.total_net_profit,
        ws.total_orders,
        ws.average_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        customer_summary
)
SELECT 
    tc.rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.total_orders,
    tc.average_order_value
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.rank;
