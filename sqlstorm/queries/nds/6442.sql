
WITH sales_summary AS (
    SELECT 
        dd.d_year AS sales_year,
        dd.d_month_seq AS sales_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS average_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_education_status IN ('Bachelors', 'Masters') AND
        dd.d_year BETWEEN 2015 AND 2021
    GROUP BY 
        dd.d_year, 
        dd.d_month_seq
), comparison AS (
    SELECT 
        sales_year,
        sales_month,
        total_sales,
        average_profit,
        unique_customers,
        LAG(total_sales) OVER (PARTITION BY sales_year ORDER BY sales_month) AS previous_month_sales
    FROM 
        sales_summary
)
SELECT 
    c.sales_year,
    c.sales_month,
    c.total_sales,
    c.average_profit,
    c.unique_customers,
    c.previous_month_sales,
    CASE 
        WHEN c.previous_month_sales IS NULL THEN 'No Data'
        WHEN c.total_sales > c.previous_month_sales THEN 'Increase'
        WHEN c.total_sales < c.previous_month_sales THEN 'Decrease'
        ELSE 'No Change'
    END AS sales_trend
FROM 
    comparison c
ORDER BY 
    c.sales_year ASC, 
    c.sales_month ASC;
