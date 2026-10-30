
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_sales_price) AS max_sales_price,
        MIN(ws_sales_price) AS min_sales_price,
        CAST(d_date AS DATE) AS sales_date
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2022
    GROUP BY 
        ws_item_sk, d_date
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
),
warehouse_summary AS (
    SELECT 
        w_warehouse_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    JOIN 
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    GROUP BY 
        w_warehouse_sk
)
SELECT 
    cs.c_customer_sk,
    cs.order_count,
    cs.total_profit,
    ss.ws_item_sk,
    ss.total_sales,
    ss.total_quantity,
    ss.avg_sales_price,
    ws.w_warehouse_sk,
    ws.total_orders,
    ws.total_profit
FROM 
    customer_summary cs
JOIN 
    sales_summary ss ON cs.order_count > 0
JOIN 
    warehouse_summary ws ON cs.total_profit > 0
WHERE 
    cs.order_count > 10
ORDER BY 
    cs.total_profit DESC, ss.total_sales DESC;
