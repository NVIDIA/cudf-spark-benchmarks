
WITH ranked_sales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        i.i_item_id,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_net_profit DESC) AS rnk
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
)
SELECT 
    rn.cs_order_number,
    rn.i_item_id,
    rn.cs_sales_price,
    rn.cs_net_profit
FROM 
    ranked_sales rn
WHERE 
    rn.rnk <= 5
ORDER BY 
    rn.cs_order_number, rn.cs_net_profit DESC;
