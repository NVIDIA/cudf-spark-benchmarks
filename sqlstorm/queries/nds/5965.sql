
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    cd.cd_marital_status,
    cd.cd_gender,
    hd.hd_buy_potential
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2023
AND ca.ca_state = 'CA'
AND cd.cd_marital_status = 'M'
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    cd.cd_marital_status,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 10;
