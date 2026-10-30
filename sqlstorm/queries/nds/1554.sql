
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count, 
        cd.cd_dep_employed_count, cd.cd_dep_college_count
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_net_profit,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        customer_summary AS cs
    WHERE 
        cs.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_summary)
),
demographics_summary AS (
    SELECT 
        cd.cd_marital_status,
        COUNT(DISTINCT hvc.c_customer_sk) AS high_value_count,
        AVG(hvc.total_net_profit) AS avg_net_profit
    FROM 
        high_value_customers AS hvc
    JOIN 
        customer_demographics AS cd ON hvc.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status
)

SELECT 
    ds.cd_marital_status,
    ds.high_value_count,
    ds.avg_net_profit,
    COALESCE(NULLIF(ds.high_value_count, 0), 1) AS safe_high_value_count
FROM 
    demographics_summary AS ds
ORDER BY 
    ds.high_value_count DESC
LIMIT 10;
