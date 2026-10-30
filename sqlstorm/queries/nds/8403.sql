
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(cs.total_sales) AS total_sales
    FROM 
        customer_demographics AS cd
    JOIN 
        CustomerSales AS cs ON cd.cd_demo_sk = cs.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesAnalysis AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        AVG(d.total_sales) AS avg_sales,
        COUNT(d.cd_demo_sk) AS demographic_count
    FROM 
        Demographics AS d
    GROUP BY 
        d.cd_gender, d.cd_marital_status, d.cd_education_status
)
SELECT 
    sa.cd_gender,
    sa.cd_marital_status,
    sa.cd_education_status,
    sa.avg_sales,
    sa.demographic_count
FROM 
    SalesAnalysis AS sa
WHERE 
    sa.avg_sales > (SELECT AVG(avg_sales) FROM SalesAnalysis)
ORDER BY 
    sa.avg_sales DESC;
