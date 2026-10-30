
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS average_order_value,
    d.d_year,
    ca.ca_city,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender,
    cd.cd_marital_status,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_web_return_amount
FROM 
    customer AS c 
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, ca.ca_city, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales DESC, average_order_value DESC
LIMIT 100;
