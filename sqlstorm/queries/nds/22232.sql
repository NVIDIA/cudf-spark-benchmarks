
WITH  customer_income AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        h.hd_income_band_sk,
        CASE 
            WHEN h.hd_buy_potential IS NULL THEN 'Unknown'
            ELSE h.hd_buy_potential 
        END AS buy_potential,
        COUNT(DISTINCT s.ss_ticket_number) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_demo_sk, h.hd_income_band_sk, 
        CASE 
            WHEN h.hd_buy_potential IS NULL THEN 'Unknown'
            ELSE h.hd_buy_potential 
        END
),
income_stats AS (
    SELECT 
        hd_income_band_sk,
        SUM(total_sales) AS total_sales_by_band,
        AVG(total_sales) AS avg_sales_per_customer,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_income
    GROUP BY 
        hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(income_stats.total_sales_by_band, 0) AS total_sales,
    income_stats.avg_sales_per_customer,
    income_stats.customer_count,
    CASE 
        WHEN income_stats.avg_sales_per_customer IS NULL THEN 'No Data'
        WHEN income_stats.avg_sales_per_customer < 10 THEN 'Low Engagement'
        ELSE 'High Engagement' 
    END AS engagement_level
FROM 
    income_band ib
LEFT JOIN 
    income_stats ON ib.ib_income_band_sk = income_stats.hd_income_band_sk
ORDER BY 
    ib.ib_lower_bound DESC
LIMIT 10
OFFSET 5;
