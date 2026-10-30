
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        dd.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, dd.d_year, dd.d_month_seq
),
demographic_summary AS (
    SELECT 
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ss.c_customer_sk) AS customer_count,
        SUM(ss.total_sales) AS total_sales_sum,
        AVG(ss.total_orders) AS avg_orders_per_customer
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status, cd.cd_gender 
)
SELECT 
    ds.cd_marital_status, 
    ds.cd_gender,
    ds.customer_count,
    ds.total_sales_sum,
    ds.avg_orders_per_customer
FROM 
    demographic_summary ds
ORDER BY 
    ds.total_sales_sum DESC, 
    ds.customer_count DESC;
