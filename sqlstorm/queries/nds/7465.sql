
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
join_summary AS (
    SELECT 
        ss.w_warehouse_id,
        cs.cd_gender,
        ss.total_net_profit,
        cs.total_net_profit AS customer_net_profit,
        ss.total_orders,
        ss.avg_sales_price,
        ss.last_sale_date
    FROM 
        sales_summary ss
    JOIN 
        customer_summary cs ON ss.total_net_profit = cs.total_net_profit
)
SELECT 
    j.w_warehouse_id,
    j.cd_gender,
    j.total_net_profit,
    j.customer_net_profit,
    j.total_orders,
    j.avg_sales_price,
    j.last_sale_date
FROM 
    join_summary j
WHERE 
    j.total_net_profit > 1000
ORDER BY 
    j.total_net_profit DESC;
