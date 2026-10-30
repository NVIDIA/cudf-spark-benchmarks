
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date,
        cd.cd_marital_status,
        cd.cd_gender,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, ib.ib_income_band_sk
),

ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    r.order_count,
    r.last_purchase_date,
    r.cd_marital_status,
    r.cd_gender,
    r.ib_income_band_sk
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.ib_income_band_sk, r.total_sales DESC;
