
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
    SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    ib.ib_income_band_sk
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M' 
    AND cd.cd_purchase_estimate > 1000 
    AND ib.ib_income_band_sk IS NOT NULL
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    ib.ib_income_band_sk
ORDER BY 
    total_store_sales DESC, 
    total_web_sales DESC, 
    total_catalog_sales DESC
LIMIT 100;
