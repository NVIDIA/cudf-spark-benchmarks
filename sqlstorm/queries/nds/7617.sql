
WITH customer_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY 
        cd_gender, cd_marital_status, ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS total_sales_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.customer_count,
    cs.total_purchase_estimate,
    cs.avg_dependent_count,
    COALESCE(ss.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(ss.total_sales_count, 0) AS total_sales_count
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.ib_income_band_sk = ss.ws_bill_cdemo_sk
JOIN 
    income_band ib ON cs.ib_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    cs.cd_gender, cs.cd_marital_status, ib.ib_lower_bound;
