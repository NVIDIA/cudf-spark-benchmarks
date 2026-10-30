
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), item_inventory AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk 
        AND inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
), top_sales AS (
    SELECT 
        sic.ws_item_sk,
        sic.total_sales,
        sic.order_count,
        ii.i_item_desc,
        ii.i_current_price,
        ii.quantity_on_hand
    FROM sales_cte sic
    JOIN item_inventory ii ON sic.ws_item_sk = ii.i_item_sk
    WHERE sic.sales_rank <= 10
)
SELECT 
    t1.i_item_desc,
    t1.total_sales,
    t1.order_count,
    t1.i_current_price,
    CASE 
        WHEN t1.quantity_on_hand = 0 THEN 'Out of Stock' 
        WHEN t1.quantity_on_hand < 10 THEN 'Low Stock' 
        ELSE 'In Stock' 
    END AS stock_status,
    (SELECT MAX(ws_net_paid) 
     FROM web_sales 
     WHERE ws_item_sk = t1.ws_item_sk) AS highest_sale,
    (SELECT AVG(ws_net_profit) 
     FROM web_sales 
     WHERE ws_item_sk = t1.ws_item_sk) AS average_profit,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_item_sk = t1.ws_item_sk AND ws_net_paid < 100) AS low_value_orders
FROM top_sales t1
LEFT JOIN store_sales t2 ON t1.ws_item_sk = t2.ss_item_sk
WHERE t1.total_sales > (SELECT AVG(total_sales) FROM sales_cte) 
  AND EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = t1.ws_item_sk AND sr_return_quantity > 0)
ORDER BY t1.total_sales DESC
LIMIT 5 OFFSET 0;
