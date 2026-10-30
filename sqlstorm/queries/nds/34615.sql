
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_year,
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2021
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
customer_income_band AS (
    SELECT 
        hd.hd_demo_sk,
        SUM(CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 0 
            ELSE 1 
        END) AS income_band_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk
),
top_customers AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales,
        RANK() OVER (PARTITION BY sh.d_year ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
    WHERE 
        sh.total_sales IS NOT NULL
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    cb.income_band_count
FROM 
    top_customers tc
JOIN 
    customer_income_band cb ON tc.c_customer_sk = cb.hd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC
LIMIT 20;
