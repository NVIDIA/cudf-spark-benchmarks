
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        c.*, 
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS rank
    FROM 
        CustomerSales c
)
SELECT 
    r.c_first_name AS first_name,
    r.c_last_name AS last_name,
    r.total_sales,
    r.total_orders,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.hd_income_band_sk
FROM 
    RankedSales r
WHERE 
    r.rank <= 5
ORDER BY 
    r.hd_income_band_sk, r.total_sales DESC;
