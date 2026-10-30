
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ws_item_sk
),
best_selling_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_quantity DESC) AS rank_quantity,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS rank_profit
    FROM sales_summary ss
),
best_items AS (
    SELECT 
        bsi.ws_item_sk,
        bsi.total_quantity,
        bsi.total_profit
    FROM best_selling_items bsi
    WHERE bsi.rank_quantity <= 10 OR bsi.rank_profit <= 10
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        bi.total_quantity,
        bi.total_profit
    FROM item i
    JOIN best_items bi ON i.i_item_sk = bi.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    id.total_quantity,
    id.total_profit
FROM item_details id
JOIN customer c ON c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ws_item_sk FROM best_items))
ORDER BY id.total_profit DESC, id.total_quantity DESC;
