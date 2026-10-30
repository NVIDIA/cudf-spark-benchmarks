
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
IncomeDistribution AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk = 1 THEN 'Low'
            WHEN hd.hd_income_band_sk = 2 THEN 'Medium'
            ELSE 'High'
        END AS income_band,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, hd.hd_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    id.income_band,
    id.customer_count
FROM 
    CustomerSales cs
JOIN 
    IncomeDistribution id ON cs.c_customer_sk = id.cd_demo_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
