
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_customer_sk
),
web_sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    ws.total_web_profit,
    rs.total_return_quantity,
    rs.total_net_loss,
    CASE 
        WHEN ws.total_web_profit > 1000 THEN 'High Value'
        WHEN ws.total_web_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    ranked_customers rc
LEFT JOIN 
    returns_summary rs ON rc.c_customer_sk = rs.sr_customer_sk 
LEFT JOIN 
    web_sales_summary ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (rs.total_return_quantity IS NULL OR rs.total_return_quantity < 5)
    AND (rc.gender_rank = 1 OR rc.gender_rank IS NULL)
    AND (rc.cd_purchase_estimate IS NOT NULL OR rc.cd_gender IS NOT NULL)
ORDER BY 
    customer_value_category, rc.c_last_name, rc.c_first_name;
