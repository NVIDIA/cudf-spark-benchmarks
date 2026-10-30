
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        hd.hd_income_band_sk,
        dd.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk, dd.d_year
),
ranking AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    r.c_customer_sk,
    r.total_quantity,
    r.total_sales,
    r.order_count,
    r.cd_gender,
    r.hd_income_band_sk,
    r.d_year
FROM 
    ranking r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.d_year, r.sales_rank;
