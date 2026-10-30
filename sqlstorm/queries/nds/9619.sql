
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        AVG(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS avg_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),

SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        AVG(avg_sales) AS avg_sales_per_customer
    FROM CustomerSales
    GROUP BY cd_gender, cd_marital_status
)

SELECT 
    ss.cd_gender,
    ss.cd_marital_status,
    ss.customer_count,
    ss.total_web_sales,
    ss.total_catalog_sales,
    ss.avg_sales_per_customer,
    ROW_NUMBER() OVER (ORDER BY total_web_sales DESC) AS rank
FROM SalesSummary AS ss
WHERE ss.total_web_sales > 1000
ORDER BY ss.avg_sales_per_customer DESC, ss.customer_count DESC;
