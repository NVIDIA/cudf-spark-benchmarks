
WITH  cte_sales AS (
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
cte_profit AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
inventory_summary AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    COUNT(cs.cs_order_number) AS total_sales_count
FROM 
    item i
LEFT JOIN 
    cte_sales cs ON i.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    cte_profit s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    inventory_summary ss ON i.i_item_sk = ss.inv_item_sk
WHERE 
    i.i_current_price BETWEEN 10.00 AND 100.00
GROUP BY 
    i.i_item_id, i.i_product_name, i.i_current_price, 
    s.total_net_profit, ss.total_quantity_on_hand
HAVING 
    COUNT(cs.cs_order_number) > 5
ORDER BY 
    total_net_profit DESC, total_quantity_on_hand DESC
LIMIT 100;
