
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, ca.ca_city, ca.ca_state
),
Order_Frequency AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_address ca
    JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
Highest_Profit_Customer AS (
    SELECT 
        full_name,
        total_orders,
        total_profit,
        ca_city,
        ca_state
    FROM 
        Customer_Info
    WHERE 
        total_profit = (SELECT MAX(total_profit) FROM Customer_Info)
)
SELECT 
    H.full_name,
    H.total_orders,
    H.total_profit,
    OF.order_count,
    OF.total_profit AS city_state_profit
FROM 
    Highest_Profit_Customer H
JOIN 
    Order_Frequency OF ON H.ca_city = OF.ca_city AND H.ca_state = OF.ca_state;
