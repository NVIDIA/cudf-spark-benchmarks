SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price) AS total_sales_price,
    AVG(ws.ws_net_profit) AS average_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND cd.cd_gender = 'F'
    AND hd.hd_buy_potential IN ('High', 'Medium')
    AND ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546 
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY 
    total_sales_price DESC
LIMIT 100;