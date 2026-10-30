
WITH sales_data AS (
    SELECT 
        ws.ws_web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        d.d_year AS year,
        d.d_quarter_seq AS quarter
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_web_site_sk, 
        ws.ws_order_number, 
        d.d_year, 
        d.d_quarter_seq
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        t.q1_sales,
        t.q2_sales,
        t.q3_sales,
        t.q4_sales
    FROM 
        customer_demographics cd
    JOIN (
        SELECT 
            sd.ws_web_site_sk,
            SUM(CASE WHEN quarter = 1 THEN total_sales ELSE 0 END) AS q1_sales,
            SUM(CASE WHEN quarter = 2 THEN total_sales ELSE 0 END) AS q2_sales,
            SUM(CASE WHEN quarter = 3 THEN total_sales ELSE 0 END) AS q3_sales,
            SUM(CASE WHEN quarter = 4 THEN total_sales ELSE 0 END) AS q4_sales
        FROM 
            sales_data sd
        GROUP BY 
            sd.ws_web_site_sk
    ) t ON cd.cd_demo_sk = t.ws_web_site_sk
),
income_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(demographics.q1_sales) AS q1_sales,
        SUM(demographics.q2_sales) AS q2_sales,
        SUM(demographics.q3_sales) AS q3_sales,
        SUM(demographics.q4_sales) AS q4_sales
    FROM 
        demographics
    LEFT JOIN 
        household_demographics hd ON demographics.cd_purchase_estimate = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    income_summary.q1_sales,
    income_summary.q2_sales,
    income_summary.q3_sales,
    income_summary.q4_sales
FROM 
    income_summary
JOIN 
    income_band ib ON income_summary.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    ib.ib_income_band_sk;
