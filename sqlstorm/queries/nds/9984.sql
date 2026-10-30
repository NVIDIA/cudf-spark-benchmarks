WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_education_status,
        DATE_PART('year', cast('2002-10-01' as date)) - c.c_birth_year AS customer_age
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date >= DATE '2001-01-01')
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_credit_rating, cd.cd_education_status, customer_age
),
SalesRanked AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    cr.c_customer_id,
    cr.total_sales,
    cr.transaction_count,
    cr.cd_gender,
    cr.cd_credit_rating,
    cr.cd_education_status,
    cr.customer_age
FROM 
    SalesRanked cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.cd_gender, cr.total_sales DESC;