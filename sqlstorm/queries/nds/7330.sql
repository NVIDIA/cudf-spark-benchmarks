
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    ib.ib_lower_bound,
    ib.ib_upper_bound 
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    c.c_first_shipto_date_sk IS NOT NULL
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_credit_rating, 
    ib.ib_lower_bound, 
    ib.ib_upper_bound
ORDER BY 
    total_store_sales DESC, 
    total_web_sales DESC, 
    total_catalog_sales DESC 
LIMIT 100;
