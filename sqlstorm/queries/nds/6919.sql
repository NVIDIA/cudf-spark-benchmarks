WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        w.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2456166 AND 2456500  
    GROUP BY 
        ws.ws_sold_date_sk, w.w_warehouse_name, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
date_summary AS (
    SELECT 
        d.d_date_sk,
        d.d_month_seq,
        d.d_quarter_seq,
        d.d_year,
        COUNT(*) AS order_count
    FROM 
        date_dim d
    JOIN 
        sales_summary ss ON d.d_date_sk = ss.ws_sold_date_sk
    GROUP BY 
        d.d_date_sk, d.d_month_seq, d.d_quarter_seq, d.d_year
)
SELECT 
    ds.d_year,
    ds.d_quarter_seq,
    SUM(ds.order_count) AS total_orders,
    AVG(ss.total_revenue) AS average_revenue_per_order,
    MAX(ss.total_quantity_sold) AS max_quantity_sold
FROM 
    date_summary ds
JOIN 
    sales_summary ss ON ds.d_date_sk = ss.ws_sold_date_sk
GROUP BY 
    ds.d_year, ds.d_quarter_seq
ORDER BY 
    ds.d_year, ds.d_quarter_seq;