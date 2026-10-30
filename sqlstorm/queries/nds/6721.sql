
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1975 AND 1995
    GROUP BY 
        c.c_customer_sk
),
DemographicStats AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(cd.cd_demo_sk) AS demographics_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        ds.avg_purchase_estimate,
        ds.demographics_count
    FROM 
        CustomerSales cs
    LEFT JOIN 
        DemographicStats ds ON cs.c_customer_sk = ds.cd_demo_sk
)
SELECT 
    sa.c_customer_sk,
    sa.total_web_sales,
    sa.avg_purchase_estimate,
    sa.demographics_count,
    CASE 
        WHEN sa.total_web_sales > 1000 THEN 'High Value'
        WHEN sa.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_web_sales DESC
LIMIT 100;
