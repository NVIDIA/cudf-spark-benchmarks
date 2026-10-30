
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        AVG(cs.total_web_sales) AS avg_sales
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FinalStats AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        SUM(d.customer_count) AS total_customers,
        AVG(d.avg_sales) AS avg_sales_per_customer
    FROM 
        Demographics d
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_education_status,
    fs.total_customers,
    fs.avg_sales_per_customer
FROM 
    FinalStats fs
ORDER BY 
    fs.total_customers DESC, fs.avg_sales_per_customer DESC;
