WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001
        AND cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
    GROUP BY 
        w.w_warehouse_id
),
promotion_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
combined_summary AS (
    SELECT 
        ss.w_warehouse_id,
        ss.total_quantity,
        ss.total_sales,
        ss.num_orders,
        ss.avg_net_profit,
        COALESCE(ps.promo_orders, 0) AS promo_orders,
        COALESCE(ps.promo_sales, 0) AS promo_sales
    FROM 
        sales_summary ss
    LEFT JOIN 
        promotion_summary ps ON ss.w_warehouse_id = ps.p_promo_id  
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    cs.total_quantity,
    cs.total_sales,
    cs.num_orders,
    cs.avg_net_profit,
    cs.promo_orders,
    cs.promo_sales
FROM 
    warehouse w
JOIN 
    combined_summary cs ON w.w_warehouse_id = cs.w_warehouse_id
ORDER BY 
    cs.total_sales DESC;