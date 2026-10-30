
WITH sales_summary AS (
    SELECT 
        COALESCE(w.w_warehouse_name, 'Unknown Warehouse') AS warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    LEFT JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN c.c_birth_year < 1980 THEN 'Millennial'
            WHEN c.c_birth_year BETWEEN 1980 AND 1995 THEN 'Gen Z'
            ELSE 'Older'
        END AS age_group,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, c.c_birth_year
), customer_ranks AS (
    SELECT 
        c.c_customer_sk,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), ranked_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.age_group,
        ci.total_orders,
        ci.total_profit,
        cr.gender_rank
    FROM 
        customer_info ci
    JOIN 
        customer_ranks cr ON ci.c_customer_sk = cr.c_customer_sk
    WHERE 
        cr.gender_rank <= 10
)
SELECT 
    rss.warehouse_name,
    rc.cd_gender,
    rc.age_group,
    SUM(rc.total_profit) AS total_profit,
    SUM(rc.total_orders) AS total_orders,
    CASE 
        WHEN AVG(rc.total_profit) IS NULL THEN 'No Sales'
        WHEN AVG(rc.total_profit) >= 5000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    sales_summary rss
JOIN 
    ranked_customers rc ON rss.total_orders > 0
GROUP BY 
    rss.warehouse_name, rc.cd_gender, rc.age_group
ORDER BY 
    total_profit DESC, rss.warehouse_name;
