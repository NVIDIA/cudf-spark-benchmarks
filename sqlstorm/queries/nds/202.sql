
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450010 AND 2450070
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(NULLIF(i.i_brand, ''), 'Unknown') AS brand_name,
        COALESCE(NULLIF(i.i_category, ''), 'Uncategorized') AS category,
        inv.inv_quantity_on_hand
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk 
    WHERE 
        inv.inv_date_sk = 2450070
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        id.i_item_id,
        id.i_product_name,
        id.brand_name,
        id.category,
        sd.total_quantity,
        sd.total_profit,
        sd.order_count
    FROM 
        SalesData sd
    JOIN 
        ItemDetails id ON sd.ws_item_sk = id.i_item_sk
    WHERE 
        sd.rank_profit <= 10
)
SELECT 
    top_items.i_item_id,
    top_items.i_product_name,
    top_items.brand_name,
    top_items.category,
    top_items.total_quantity,
    top_items.total_profit,
    top_items.order_count,
    CASE 
        WHEN top_items.total_profit > 1000 THEN 'High Profit'
        WHEN top_items.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    (SELECT 
         COUNT(DISTINCT ws_bill_customer_sk) 
     FROM 
         web_sales ws 
     WHERE 
         ws.ws_item_sk = top_items.ws_item_sk 
         AND ws.ws_sold_date_sk BETWEEN 2450010 AND 2450070) AS unique_customers
FROM 
    TopItems top_items
ORDER BY 
    top_items.total_profit DESC;
