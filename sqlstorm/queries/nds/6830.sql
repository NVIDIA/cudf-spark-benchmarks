WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_quantity) AS avg_quantity_sold
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 1998 AND 2000
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F')
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ss.w_warehouse_name,
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_quantity_sold,
    cs.cd_gender,
    cs.total_profit,
    cs.total_orders
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.d_year = (SELECT MIN(d_year) FROM sales_summary) 
ORDER BY 
    ss.total_sales DESC, cs.total_profit DESC;