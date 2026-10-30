
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    MAX(d.d_date) AS last_purchase_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
    cd.cd_education_status, ib.ib_lower_bound, ib.ib_upper_bound
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
