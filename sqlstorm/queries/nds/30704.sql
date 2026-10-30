
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ranked_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS sales_rank
    FROM 
        sales_cte
    WHERE 
        rn = 1
),
high_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_net_profit,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        ranked_sales rs
        JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.total_net_profit > (SELECT AVG(total_net_profit) FROM ranked_sales)
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    COALESCE(SUM(hs.total_net_profit), 0) AS total_profit,
    STRING_AGG(DISTINCT i.i_brand, ', ') AS brands
FROM 
    customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN high_sales hs ON c.c_customer_sk = hs.ws_item_sk
    LEFT JOIN item i ON hs.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_profit DESC
LIMIT 10;
