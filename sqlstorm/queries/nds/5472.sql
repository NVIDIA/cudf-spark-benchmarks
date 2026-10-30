
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.purchase_rank <= 5
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_performance AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        sd.total_profit,
        sd.total_orders,
        CASE 
            WHEN sd.total_orders > 0 THEN ROUND(sd.total_profit / sd.total_orders, 2)
            ELSE 0
        END AS average_profit_per_order
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_data sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.total_profit,
    cp.total_orders,
    cp.average_profit_per_order
FROM 
    customer_performance cp
ORDER BY 
    cp.total_profit DESC
LIMIT 10;
