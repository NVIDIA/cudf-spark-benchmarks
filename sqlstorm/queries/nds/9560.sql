
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_profit,
        cs.total_orders,
        d.avg_purchase_estimate
    FROM 
        customer_sales cs
    JOIN 
        demographics d ON cs.c_customer_sk = d.cd_demo_sk
)
SELECT 
    s.c_customer_sk,
    s.total_profit,
    s.total_orders,
    s.avg_purchase_estimate,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank,
    RANK() OVER (ORDER BY s.total_orders DESC) AS order_rank
FROM 
    sales_summary s
WHERE 
    s.total_profit > 1000
ORDER BY 
    s.total_profit DESC, 
    s.total_orders DESC
LIMIT 50;
