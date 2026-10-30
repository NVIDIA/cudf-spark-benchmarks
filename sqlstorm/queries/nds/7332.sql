
WITH sales_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        SUM(ws.ws_net_paid) AS customer_total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
performance_summary AS (
    SELECT 
        ss.i_item_id,
        ss.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        cs.customer_orders,
        cs.customer_total_spent,
        cs.cd_gender
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.total_orders = cs.customer_orders
    ORDER BY 
        total_sales DESC
)
SELECT 
    ps.i_item_id,
    ps.i_item_desc,
    ps.total_quantity,
    ps.total_sales,
    ps.customer_orders,
    ps.customer_total_spent,
    ps.cd_gender
FROM 
    performance_summary ps
WHERE 
    ps.total_sales > 1000
LIMIT 100;
