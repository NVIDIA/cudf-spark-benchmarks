
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
sales_summary AS (
    SELECT 
        hd_income_band_sk, 
        COUNT(*) AS customer_count, 
        AVG(total_sales) AS avg_sales, 
        AVG(order_count) AS avg_order_count
    FROM 
        customer_data
    GROUP BY 
        hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(ss.customer_count, 0) AS customer_count,
    COALESCE(ss.avg_sales, 0) AS avg_sales,
    COALESCE(ss.avg_order_count, 0) AS avg_order_count
FROM 
    income_band ib
LEFT JOIN 
    sales_summary ss ON ib.ib_income_band_sk = ss.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
