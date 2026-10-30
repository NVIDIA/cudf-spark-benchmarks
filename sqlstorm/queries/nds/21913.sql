
WITH filtered_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_purchase_estimate > 500 AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
),
inventory_summary AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
sales_summary AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales,
           AVG(ws.ws_list_price) AS avg_list_price,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT f.c_first_name, f.c_last_name, 
       COALESCE(s.total_sales, 0) AS total_sales, 
       COALESCE(i.total_inventory, 0) AS total_inventory,
       CASE 
           WHEN COALESCE(s.total_sales, 0) = 0 THEN 'No Sales'
           WHEN COALESCE(i.total_inventory, 0) = 0 THEN 'Out of Stock'
           ELSE 'Available'
       END AS stock_status
FROM filtered_customers f
LEFT JOIN sales_summary s ON f.c_customer_sk = s.ws_item_sk
LEFT JOIN inventory_summary i ON s.ws_item_sk = i.inv_item_sk
WHERE f.ca_state IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_country = 'USA')
AND (f.ca_city LIKE '%York%' OR f.ca_city IS NULL)
ORDER BY f.c_last_name DESC, f.c_first_name ASC
LIMIT 50;
