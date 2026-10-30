
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    d_year,
    d_month_seq,
    ca_state
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk
GROUP BY 
    d_year, 
    d_month_seq, 
    ca_state
ORDER BY 
    d_year, 
    d_month_seq, 
    total_sales DESC
LIMIT 100;
