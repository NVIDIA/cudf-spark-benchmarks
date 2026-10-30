
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender, 
        ci.cd_marital_status, 
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    WHERE 
        ci.gender_rank <= 5
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid_inc_tax IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
sales_analysis AS (
    SELECT 
        ts.c_customer_sk, 
        ts.c_first_name, 
        ts.c_last_name, 
        ts.cd_gender,
        COALESCE(SUM(i.total_sales), 0) AS total_item_sales,
        COALESCE(AVG(i.avg_net_profit), 0) AS average_net_profit
    FROM 
        top_customers ts
    LEFT JOIN 
        item_sales i ON ts.c_customer_sk = i.ws_item_sk
    GROUP BY 
        ts.c_customer_sk, 
        ts.c_first_name, 
        ts.c_last_name, 
        ts.cd_gender
)
SELECT 
    sa.cd_gender,
    COUNT(DISTINCT sa.c_customer_sk) AS customer_count,
    SUM(sa.total_item_sales) AS overall_sales,
    MAX(sa.average_net_profit) AS highest_avg_profit,
    MIN(CASE WHEN sa.total_item_sales > 100 THEN sa.c_customer_sk END) AS first_high_sales_customer
FROM 
    sales_analysis sa
WHERE 
    sa.total_item_sales IS NOT NULL 
    OR sa.average_net_profit IS NOT NULL
GROUP BY 
    sa.cd_gender
HAVING 
    COUNT(DISTINCT sa.c_customer_sk) > 2
ORDER BY 
    overall_sales DESC NULLS LAST;
