
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        w.w_warehouse_id, d.d_month_seq
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_gender
),
final_summary AS (
    SELECT 
        s.w_warehouse_id,
        s.d_month_seq,
        c.cd_gender,
        s.total_sales,
        s.total_orders,
        s.avg_sales_price,
        c.customer_count,
        c.total_spent
    FROM 
        sales_summary s
    JOIN 
        customer_summary c ON c.total_spent > 1000
)
SELECT 
    w.w_warehouse_id,
    d.d_month_seq,
    cd.cd_gender,
    SUM(fs.total_sales) AS grand_total_sales,
    COUNT(fs.total_orders) AS grand_total_orders,
    AVG(fs.avg_sales_price) AS grand_avg_sales_price,
    SUM(fs.customer_count) AS total_customers,
    SUM(fs.total_spent) AS grand_total_spent
FROM 
    final_summary fs
JOIN 
    warehouse w ON fs.w_warehouse_id = w.w_warehouse_id
JOIN 
    date_dim d ON fs.d_month_seq = d.d_month_seq
JOIN 
    customer_demographics cd ON fs.cd_gender = cd.cd_gender
GROUP BY 
    w.w_warehouse_id, d.d_month_seq, cd.cd_gender
ORDER BY 
    grand_total_sales DESC;
