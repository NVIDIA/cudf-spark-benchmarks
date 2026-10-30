
WITH RevenueData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT(ws.ws_order_number)) AS order_count,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_income_band_sk
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ib.ib_income_band_sk
),
RankedRevenue AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        d_year,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ib_income_band_sk,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RevenueData
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.order_count,
    r.d_year,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.ib_income_band_sk
FROM 
    RankedRevenue AS r
WHERE 
    sales_rank <= 10
ORDER BY 
    r.d_year, r.total_sales DESC;
