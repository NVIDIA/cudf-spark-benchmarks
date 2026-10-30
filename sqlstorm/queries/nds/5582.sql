
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
demographic_stats AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
warehouse_sales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cs.c_customer_sk,
    ds.cd_demo_sk,
    ws.w_warehouse_sk,
    cs.total_orders,
    cs.total_profit,
    cs.total_quantity,
    ds.avg_purchase_estimate,
    ds.customer_count,
    ws.total_sales
FROM 
    customer_stats cs
JOIN 
    demographic_stats ds ON ds.customer_count > 50
JOIN 
    warehouse_sales ws ON ws.total_sales > 10000
ORDER BY 
    cs.total_profit DESC
LIMIT 100;
