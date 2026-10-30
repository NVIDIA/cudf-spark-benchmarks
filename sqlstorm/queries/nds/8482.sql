
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_ext_sales_price) AS avg_order_value,
        d_year AS sales_year,
        d_month_seq AS sales_month
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year BETWEEN 2021 AND 2022
    GROUP BY 
        ws_bill_customer_sk, d_year, d_month_seq
), 
demographics_summary AS (
    SELECT 
        c.c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    ds.customer_id,
    ds.total_sales,
    ds.total_orders,
    ds.avg_order_value,
    ds.sales_year,
    ds.sales_month,
    dem.cd_gender,
    dem.cd_marital_status,
    dem.cd_education_status,
    dem.total_catalog_orders
FROM 
    sales_summary ds
JOIN 
    demographics_summary dem ON ds.customer_id = dem.c_customer_sk
WHERE 
    ds.total_sales > 1000
ORDER BY 
    ds.sales_year, ds.sales_month, ds.total_sales DESC
LIMIT 100;
