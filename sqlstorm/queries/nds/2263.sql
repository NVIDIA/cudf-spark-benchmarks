
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as rank
    FROM web_sales
),
total_returns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM web_returns
    GROUP BY wr_item_sk
)

SELECT 
    a.ca_city,
    SUM(s.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT s.ws_order_number) AS unique_orders,
    COALESCE(r.total_returned, 0) AS total_returns,
    CASE 
        WHEN SUM(s.ws_net_profit) > 10000 THEN 'High Performer'
        WHEN SUM(s.ws_net_profit) BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    web_sales s
JOIN 
    customer c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    total_returns r ON s.ws_item_sk = r.wr_item_sk
WHERE 
    s.ws_ship_date_sk BETWEEN 20230101 AND 20231231
    AND (c.c_birth_year < 1990 AND c.c_preferred_cust_flag = 'Y')
GROUP BY 
    a.ca_city, r.total_returned
HAVING 
    SUM(s.ws_net_profit) > 5000
ORDER BY 
    total_net_profit DESC;
