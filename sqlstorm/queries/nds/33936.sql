
WITH  sales_data AS (
    SELECT ws_order_number, ws_item_sk, ws_quantity, ws_sales_price, 
           ws_ext_sales_price, ws_net_profit, 
           ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451113 AND 2451489
),
inventory_data AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_order_number > 999)
    GROUP BY inv_item_sk
),
customer_return_data AS (
    SELECT cr_item_sk, COUNT(*) AS return_count, 
           SUM(cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk
),
sales_summary AS (
    SELECT sd.ws_order_number, sd.ws_item_sk, 
           SUM(sd.ws_quantity) AS total_quantity_sold,
           SUM(sd.ws_ext_sales_price) AS total_sales, 
           COALESCE(ir.total_inventory, 0) AS available_stock,
           COALESCE(cr.return_count, 0) AS number_of_returns,
           COALESCE(cr.total_return_amount, 0) AS total_return_value,
           ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY SUM(sd.ws_ext_sales_price) DESC) AS sales_rank
    FROM sales_data sd
    LEFT JOIN inventory_data ir ON sd.ws_item_sk = ir.inv_item_sk
    LEFT JOIN customer_return_data cr ON sd.ws_item_sk = cr.cr_item_sk
    GROUP BY sd.ws_order_number, sd.ws_item_sk, ir.total_inventory, cr.return_count, cr.total_return_amount
)
SELECT ss.ws_order_number, ss.ws_item_sk, ss.total_quantity_sold, ss.total_sales, 
       ss.available_stock, ss.number_of_returns, ss.total_return_value,
       CASE 
           WHEN ss.total_sales > 500 THEN 'High Value'
           WHEN ss.total_sales BETWEEN 200 AND 500 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS sales_category
FROM sales_summary ss
WHERE ss.sales_rank <= 5
ORDER BY ss.total_sales DESC;
