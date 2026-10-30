
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_net_paid_inc_tax) AS avg_payment,
    d.d_year,
    d.d_month_seq,
    d.d_dow,
    d.d_weekend,
    ca.ca_city AS address_city,
    ca.ca_state AS address_state,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_income_band_sk
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    household_demographics hhd ON c.c_current_hdemo_sk = hhd.hd_demo_sk
JOIN 
    income_band ib ON hhd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    d.d_year = 2023
    AND d.d_month_seq BETWEEN 1 AND 3
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_dow, d.d_weekend, 
    ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
