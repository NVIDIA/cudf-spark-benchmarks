
WITH sales_summary AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_web_site_sk
),
top_sales AS (
    SELECT 
        ss.ws_web_site_sk,
        ss.total_orders,
        ss.total_sales,
        ss.total_discount,
        ss.avg_sales_price,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    w.w_warehouse_name,
    t.total_orders,
    t.total_sales,
    t.total_discount,
    t.avg_sales_price
FROM 
    top_sales t
JOIN 
    warehouse w ON t.ws_web_site_sk = w.w_warehouse_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
