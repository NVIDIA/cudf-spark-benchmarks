SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_net_profit) AS max_profit,
    w.w_warehouse_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_purchase_estimate > 100 
    AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600  
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, w.w_warehouse_name
ORDER BY 
    total_sales DESC
LIMIT 100;