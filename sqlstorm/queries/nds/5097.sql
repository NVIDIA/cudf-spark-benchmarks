
WITH MonthlySales AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        dd.d_year, dd.d_month_seq
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ms.total_sales) AS sales_per_demographic
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        MonthlySales ms ON ms.d_year = 2023
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.sales_per_demographic,
    ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.sales_per_demographic DESC) AS sales_rank
FROM 
    Demographics d
WHERE 
    d.sales_per_demographic > (SELECT AVG(sales_per_demographic) FROM Demographics)
ORDER BY 
    d.cd_gender, d.sales_per_demographic DESC;
