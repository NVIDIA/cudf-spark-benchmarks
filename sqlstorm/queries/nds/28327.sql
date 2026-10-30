
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used,
    LPAD(CAST(cd.cd_purchase_estimate AS STRING), 10, '0') AS padded_purchase_estimate,
    (CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END) AS marital_status,
    REPLACE(c.c_email_address, '@', '[at]') AS obfuscated_email
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion AS p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    ca.ca_city LIKE 'San%' 
    AND cd.cd_gender = 'F' 
    AND ws.ws_sold_date_sk > 1000
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_purchase_estimate, 
    cd.cd_marital_status, 
    c.c_email_address
ORDER BY 
    total_sales DESC
LIMIT 100;
