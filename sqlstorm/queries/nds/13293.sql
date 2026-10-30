
SELECT 
    SUM(ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws_order_number) AS total_orders, 
    AVG(ws_net_paid_inc_tax) AS avg_order_value 
FROM 
    web_sales 
JOIN 
    web_site ON web_sales.ws_web_site_sk = web_site.web_site_sk 
JOIN 
    customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk 
JOIN 
    date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk 
WHERE 
    date_dim.d_year = 2023 
    AND customer.c_current_cdemo_sk IS NOT NULL 
GROUP BY 
    web_site.web_name 
ORDER BY 
    total_sales DESC;
