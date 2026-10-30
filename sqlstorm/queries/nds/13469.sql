WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451580 
    GROUP BY 
        ws_item_sk
), 
address_data AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state
    FROM 
        customer_address
)
SELECT 
    sd.ws_item_sk,
    ad.ca_city,
    ad.ca_state,
    sd.total_quantity,
    sd.total_profit
FROM 
    sales_data sd
JOIN 
    customer c ON sd.ws_item_sk = c.c_current_addr_sk
JOIN 
    address_data ad ON c.c_current_addr_sk = ad.ca_address_sk
ORDER BY 
    sd.total_profit DESC
LIMIT 10;