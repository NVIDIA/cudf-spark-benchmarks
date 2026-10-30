
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS overall_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND ws.ws_sales_price > 0
),
item_promotions AS (
    SELECT 
        cs.cs_item_sk, 
        cs.cs_order_number,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM 
        catalog_sales cs 
    WHERE 
        cs.cs_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_dow IN (1, 2) AND d.d_year = 2023)
    GROUP BY 
        cs.cs_item_sk, 
        cs.cs_order_number
)
SELECT 
    a.ca_city,
    a.ca_state,
    d.d_year,
    SUM(COALESCE(r.ws_quantity, 0)) AS total_quantity,
    SUM(COALESCE(r.ws_net_profit, 0)) AS total_profit,
    AVG(COALESCE(p.total_discount, 0)) AS avg_discount,
    COUNT(DISTINCT r.ws_order_number) AS unique_orders,
    CASE 
        WHEN SUM(COALESCE(r.ws_net_profit, 0)) > 5000 THEN 'High Profit'
        WHEN SUM(COALESCE(r.ws_net_profit, 0)) BETWEEN 2000 AND 5000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    customer_address a
FULL OUTER JOIN ranked_sales r ON a.ca_address_sk = r.ws_item_sk 
LEFT JOIN item_promotions p ON r.ws_order_number = p.cs_order_number 
JOIN date_dim d ON d.d_date_sk = r.ws_order_number -- Fixed for proper join
WHERE 
    d.d_year IN (2022, 2023)
GROUP BY 
    a.ca_city, 
    a.ca_state, 
    d.d_year
HAVING 
    SUM(COALESCE(r.ws_quantity, 0)) > 100
ORDER BY 
    total_profit DESC, 
    a.ca_city ASC;
