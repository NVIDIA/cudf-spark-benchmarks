
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        c.c_customer_id
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_transactions,
        CASE 
            WHEN cs.total_sales < 1000 THEN 'Low'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS sales_category
    FROM 
        CustomerSales cs
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(*) AS count_by_category
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    ss.sales_category,
    SUM(dd.count_by_category) AS demographic_count
FROM 
    SalesSummary ss
LEFT JOIN 
    Demographics dd ON ss.total_transactions > 0
GROUP BY 
    ss.sales_category
ORDER BY 
    CASE ss.sales_category 
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
    END;
