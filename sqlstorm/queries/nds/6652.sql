
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_sales_price) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
    AVG(ss.ss_sales_price) AS avg_purchase_value,
    CASE 
        WHEN COUNT(DISTINCT ss.ss_ticket_number) = 0 THEN 0 
        ELSE SUM(ss.ss_sales_price) / COUNT(DISTINCT ss.ss_ticket_number) 
    END AS avg_spent_per_order,
    d.d_year AS purchase_year,
    cc.cc_name AS call_center_name
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    call_center cc ON c.c_current_hdemo_sk = cc.cc_call_center_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year,
    cc.cc_name
HAVING 
    SUM(ss.ss_sales_price) > 5000
ORDER BY 
    total_spent DESC 
LIMIT 100;
