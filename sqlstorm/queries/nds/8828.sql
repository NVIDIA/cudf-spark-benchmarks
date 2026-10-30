
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_item_sk, d.d_date
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_customer_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_net_profit,
        ss.total_orders,
        cs.total_orders AS customer_orders,
        cs.total_customer_profit,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS profit_rank
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_summary cs ON ss.ws_item_sk = cs.c_customer_sk
)
SELECT 
    r.ws_item_sk,
    r.total_quantity_sold,
    r.total_sales,
    r.total_net_profit,
    r.total_orders,
    r.customer_orders,
    r.total_customer_profit,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    ranked_sales r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
JOIN 
    warehouse w ON i.i_brand_id = w.w_warehouse_sk
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = r.total_orders % 10
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.total_net_profit DESC;
