
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_order_value,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY SUM(ws.ws_net_profit) DESC) AS marital_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),

top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_profit,
        cs.avg_order_value,
        CASE 
            WHEN cs.marital_rank < 5 THEN 'Top 5%'
            ELSE 'Other'
        END AS customer_category
    FROM 
        customer_stats cs
    WHERE 
        cs.total_orders > 10
)

SELECT 
    t.c_first_name,
    t.c_last_name,
    COALESCE(reasons.r_reason_desc, 'No Reason') AS return_reason,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_returns,
    SUM(ws.ws_net_profit) AS total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_sales_orders,
    AVG(NULLIF(ws.ws_net_paid, 0)) AS avg_sales_order_value
FROM 
    top_customers t
LEFT JOIN 
    catalog_returns cr ON t.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    reason reasons ON cr.cr_reason_sk = reasons.r_reason_sk
LEFT JOIN 
    store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (t.customer_category = 'Top 5%' OR t.total_profit > 5000) AND
    (ws.ws_sales_price IS NOT NULL OR ss.ss_sales_price IS NOT NULL)
GROUP BY 
    t.c_first_name, t.c_last_name, reasons.r_reason_desc
HAVING 
    SUM(ws.ws_net_profit) BETWEEN 1000 AND 10000
ORDER BY 
    total_revenue DESC NULLS LAST;
