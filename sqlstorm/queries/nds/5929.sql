
SELECT 
    c.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cd.cd_purchase_estimate >= 1000 
    AND ws.ws_sold_date_sk BETWEEN 2459345 AND 2459346
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
LIMIT 100;
