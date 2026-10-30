
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451879  
    GROUP BY 
        ws_item_sk
), 
PopularItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity,
        RankedSales.total_net_profit,
        RankedSales.ws_item_sk
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rank <= 10  
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(pi.total_net_profit) AS total_revenue
FROM 
    PopularItems pi
JOIN 
    customer c ON pi.ws_item_sk = c.c_current_addr_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue DESC;
