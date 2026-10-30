
WITH customer_info AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        address_info.ca_city,
        address_info.ca_state,
        address_info.ca_country,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address address_info ON c.c_current_addr_sk = address_info.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
total_sales_per_customer AS (
    SELECT 
        si.ws_bill_customer_sk,
        COUNT(si.ws_order_number) AS order_count,
        SUM(si.ws_net_profit) AS total_profit
    FROM 
        sales_info si
    GROUP BY 
        si.ws_bill_customer_sk
)

SELECT 
    ci.full_name, 
    ci.c_email_address, 
    ci.cd_gender, 
    ci.ca_city, 
    ci.ca_state, 
    ci.ca_country, 
    ts.order_count, 
    ts.total_profit
FROM 
    customer_info ci
LEFT JOIN 
    total_sales_per_customer ts ON ci.c_customer_sk = ts.ws_bill_customer_sk
WHERE 
    ts.total_profit > 1000 
ORDER BY 
    ts.total_profit DESC, 
    ci.full_name ASC
LIMIT 50;
