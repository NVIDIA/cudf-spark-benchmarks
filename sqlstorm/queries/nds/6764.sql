
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_coupon_amt) AS total_coupons_used
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_demographics_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS warehouse_total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS warehouse_order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.order_count,
    ss.avg_sales_price,
    ss.total_quantity,
    ss.total_coupons_used,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_spent,
    cd.avg_purchase_estimate,
    ws.w_warehouse_name,
    ws.warehouse_total_sales,
    ws.warehouse_order_count
FROM 
    sales_summary ss
JOIN 
    customer_demographics_analysis cd ON ss.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
JOIN 
    warehouse_sales_summary ws ON ss.total_sales > 10000 
ORDER BY 
    ss.d_year;
