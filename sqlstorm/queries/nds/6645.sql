
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, d.d_year
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.d_year,
        RANK() OVER (PARTITION BY cs.cd_gender, cs.cd_marital_status ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    COUNT(r.c_customer_sk) AS customer_count,
    AVG(r.total_sales) AS avg_sales,
    MIN(r.total_sales) AS min_sales,
    MAX(r.total_sales) AS max_sales
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.cd_gender, r.cd_marital_status
ORDER BY 
    r.cd_gender, r.cd_marital_status;
