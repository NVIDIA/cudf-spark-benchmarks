
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicSales AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS total_demographic_sales,
        SUM(cs.order_count) AS total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS month_sales,
        COUNT(ws.ws_order_number) AS month_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ms.d_year,
    ms.d_month_seq,
    ds.total_demographic_sales,
    ds.total_orders,
    ms.month_sales,
    ms.month_orders
FROM 
    DemographicSales ds
JOIN 
    MonthlySales ms ON ds.total_orders > 10
ORDER BY 
    ds.cd_gender, ds.cd_marital_status, ms.d_year DESC, ms.d_month_seq DESC;
