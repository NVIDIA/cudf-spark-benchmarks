WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459645 AND 2459650 
    GROUP BY 
        ws_item_sk
),
Top_Sales AS (
    SELECT 
        ws_item_sk, 
        total_net_profit, 
        total_orders
    FROM 
        Sales_CTE
    WHERE 
        rank <= 10
),
Item_Details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(NULLIF(i.i_color, ''), 'N/A') AS item_color,
        CASE 
            WHEN i.i_current_price >= 50 THEN 'High Value'
            WHEN i.i_current_price BETWEEN 20 AND 50 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        item i
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.i_brand,
    id.item_color,
    id.value_category,
    ts.total_net_profit,
    ts.total_orders,
    CASE 
        WHEN ts.total_orders > 5 THEN 'Frequent Seller'
        ELSE 'Occasional Seller'
    END AS seller_category
FROM 
    Top_Sales ts
JOIN 
    Item_Details id ON ts.ws_item_sk = id.i_item_sk
ORDER BY 
    ts.total_net_profit DESC;