
WITH Top_Customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450057 AND 2453012
    GROUP BY 
        c.c_customer_id, cd.cd_marital_status, cd.cd_gender, ca.ca_city
),
Top_Products AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450057 AND 2453012
    GROUP BY 
        i.i_item_id
),
Customer_Analysis AS (
    SELECT 
        tc.c_customer_id,
        tc.total_net_profit,
        tp.total_profit,
        tc.cd_marital_status,
        tc.cd_gender,
        tc.ca_city,
        RANK() OVER (PARTITION BY tc.cd_marital_status, tc.cd_gender ORDER BY tc.total_net_profit DESC) as profit_rank
    FROM 
        Top_Customers tc
    JOIN 
        Top_Products tp ON tp.total_profit > 1000
)
SELECT 
    ca.c_customer_id,
    ca.total_net_profit,
    ca.total_profit,
    ca.cd_marital_status,
    ca.cd_gender,
    ca.ca_city,
    ca.profit_rank
FROM 
    Customer_Analysis ca
WHERE 
    ca.profit_rank <= 10
ORDER BY 
    ca.cd_marital_status, ca.cd_gender, ca.total_net_profit DESC;
