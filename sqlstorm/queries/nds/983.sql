
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),

sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_bill_customer_sk
),

ranked_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_spent,
        ss.total_orders,
        ss.avg_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.customer_sk
    WHERE 
        cs.purchase_rank <= 10
)

SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.total_orders,
    COALESCE(rc.avg_profit, 0) AS avg_profit,
    CASE 
        WHEN rc.spending_rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_type
FROM 
    ranked_customers rc
ORDER BY 
    rc.total_spent DESC
LIMIT 100;
