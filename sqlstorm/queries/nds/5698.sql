
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(ss.ss_ticket_number) AS transaction_count, 
    SUM(ss.ss_ext_discount_amt) AS total_discount, 
    cd.cd_gender, 
    SUM(sr.sr_return_amt) AS total_returns, 
    AVG(ss.ss_sales_price) AS avg_sale_price,
    d.d_year AS sales_year
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2019 AND 2023
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, d.d_year
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC, avg_sale_price ASC
LIMIT 100;
