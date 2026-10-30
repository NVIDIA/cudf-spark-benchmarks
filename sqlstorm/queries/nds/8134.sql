
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year, 
        d.d_month_seq AS sales_month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.sales_year,
    ss.sales_month,
    ss.total_sales,
    ss.total_orders,
    ss.total_quantity,
    ss.avg_net_paid,
    ss.avg_sales_price,
    ss.avg_discount,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_catalog_sales,
    ds.total_store_sales,
    ds.total_web_sales
FROM 
    sales_summary ss 
JOIN 
    demographics_summary ds ON 1=1
ORDER BY 
    ss.sales_year, ss.sales_month, ds.cd_gender, ds.cd_marital_status;
