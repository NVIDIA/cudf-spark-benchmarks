SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    CASE 
        WHEN cd_gender = 'M' THEN 'Male' 
        WHEN cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' 
    END AS gender,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_sales_price) AS total_web_sales,
    SUM(ws.ws_ext_discount_amt) AS total_web_discounts,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    cast('2002-10-01' as date) AS report_date
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd_gender, ca.ca_city, ca.ca_state
ORDER BY total_web_sales DESC
LIMIT 100;