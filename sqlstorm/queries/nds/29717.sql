
WITH CustomerData AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length,
        UPPER(c.c_email_address) AS email_upper
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY') AND 
        cd.cd_marital_status = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        CONCAT_WS('-', ws.ws_order_number, ws.ws_quantity) AS order_detail,
        CAST(ws.ws_sales_price AS DECIMAL(10, 2)) AS formatted_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d) 
),
MergedData AS (
    SELECT 
        cd.full_name,
        cd.email_upper,
        sd.order_detail,
        sd.formatted_price,
        sd.ws_net_profit
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.email_upper LIKE '%' || SUBSTRING(sd.order_detail FROM POSITION('-' IN sd.order_detail) + 1) || '%'
)
SELECT 
    full_name, 
    email_upper, 
    COUNT(order_detail) AS total_orders,
    SUM(ws_net_profit) AS total_profit, 
    AVG(formatted_price) AS avg_sales_price
FROM 
    MergedData
GROUP BY 
    full_name, email_upper
HAVING 
    COUNT(order_detail) > 1
ORDER BY 
    total_profit DESC;
