
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        haha.hd_income_band_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics haha ON c.c_current_hdemo_sk = haha.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        haha.hd_income_band_sk
),
SalesRanking AS (
    SELECT 
        cu.*, 
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSummary cu
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.hd_income_band_sk,
    s.total_sales,
    s.sales_rank
FROM 
    SalesRanking s
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.hd_income_band_sk, 
    s.sales_rank;
