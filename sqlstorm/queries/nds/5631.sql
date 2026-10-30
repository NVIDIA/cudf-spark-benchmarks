
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_sales_price) AS total_sales, 
    SUM(ws.ws_ext_discount_amt) AS total_discounts, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status,
    ca.ca_city,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND d.d_month_seq IN (1, 2, 3) 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    ca.ca_city, 
    d.d_year, 
    d.d_month_seq
ORDER BY 
    total_sales DESC 
LIMIT 10;
