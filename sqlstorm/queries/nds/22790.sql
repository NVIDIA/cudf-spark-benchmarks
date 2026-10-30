
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.rn <= 5
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
final_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        COALESCE(ss.total_profit, 0) AS total_profit,
        COALESCE(ss.total_orders, 0) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ss.total_profit, 0) DESC) AS rank
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_summary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name || ' ' || fr.c_last_name AS full_name,
    fr.cd_gender,
    fr.total_profit,
    fr.total_orders,
    CASE 
        WHEN fr.total_orders = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    CASE 
        WHEN fr.rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    final_report fr
WHERE 
    fr.total_profit > (SELECT AVG(total_profit) FROM sales_summary)
ORDER BY 
    fr.total_profit DESC, fr.c_customer_sk;
