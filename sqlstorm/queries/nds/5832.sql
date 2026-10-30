WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 1999 AND 2001
    GROUP BY 
        d.d_year, w.w_warehouse_id
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_credit_rating = 'Good' THEN 1 ELSE 0 END) AS good_credit_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.sales_year,
    ss.w_warehouse_id,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.avg_net_profit,
    cs.customer_count,
    cs.good_credit_customers
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON cs.cd_marital_status = 'M'  
ORDER BY 
    ss.sales_year, ss.w_warehouse_id;