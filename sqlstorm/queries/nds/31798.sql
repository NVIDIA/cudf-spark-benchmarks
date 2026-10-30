
WITH  sales_cte AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
address_agg AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    a.ca_state,
    a.unique_customers,
    a.avg_purchase_estimate,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_profit, 0) AS total_profit
FROM 
    address_agg AS a
LEFT JOIN 
    sales_cte AS s ON s.ws_item_sk IN (SELECT DISTINCT i.i_item_sk FROM item AS i WHERE i.i_current_price > 100)
ORDER BY 
    a.unique_customers DESC 
LIMIT 10;
