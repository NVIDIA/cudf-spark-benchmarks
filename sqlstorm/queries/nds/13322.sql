
SELECT 
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    d.d_year AS sale_year
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_year
ORDER BY 
    sale_year DESC;
