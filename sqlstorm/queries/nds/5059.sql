
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year, d.d_month_seq
),
MonthlySales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(total_sales) AS monthly_sales
    FROM 
        CustomerSales
    GROUP BY 
        d_year, d_month_seq
),
RankedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        monthly_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY monthly_sales DESC) AS sales_rank
    FROM 
        MonthlySales
)
SELECT 
    d_year,
    d_month_seq,
    monthly_sales
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, d_month_seq, sales_rank;
