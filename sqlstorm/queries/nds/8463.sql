
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales AS cs
    JOIN 
        customer_demographics AS cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > 1000
),
SalesSummary AS (
    SELECT 
        COUNT(*) AS num_customers,
        SUM(total_sales) AS total_sales,
        AVG(total_sales) AS avg_sales,
        MIN(total_sales) AS min_sales,
        MAX(total_sales) AS max_sales
    FROM 
        HighValueCustomers
),
MonthlySales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    ss.num_customers,
    ss.total_sales,
    ss.avg_sales,
    ss.min_sales,
    ss.max_sales,
    ms.d_year,
    ms.d_month_seq,
    ms.monthly_sales
FROM 
    HighValueCustomers AS hvc,
    SalesSummary AS ss,
    MonthlySales AS ms
ORDER BY 
    ms.d_year DESC, ms.d_month_seq DESC, hvc.total_sales DESC;
