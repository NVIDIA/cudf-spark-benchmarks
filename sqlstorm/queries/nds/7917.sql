
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_sales_price) AS average_transaction_value,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    w.w_warehouse_name
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    warehouse w ON s.s_company_id = w.w_warehouse_sk
LEFT JOIN 
    store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, r.r_reason_desc, w.w_warehouse_name
HAVING 
    SUM(ss.ss_sales_price) > 1000 
ORDER BY 
    total_sales DESC
LIMIT 100;
