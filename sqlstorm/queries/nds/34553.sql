
WITH  CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, c_current_addr_sk,
           ROW_NUMBER() OVER (PARTITION BY c_birth_year ORDER BY c_last_name) AS rn
    FROM customer
    WHERE c_birth_year IS NOT NULL
),
InventoryCTE AS (
    SELECT inv_item_sk, SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY inv_item_sk
),
SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales, ws_web_site_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_item_sk, ws_web_site_sk
),
StoreSalesCTE AS (
    SELECT ss_item_sk, SUM(ss_sales_price) AS total_store_sales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ss_item_sk
)
SELECT c.c_first_name, c.c_last_name, 
       COALESCE(s.total_sales, 0) AS web_sales_total,
       COALESCE(ss.total_store_sales, 0) AS store_sales_total,
       i.total_inventory,
       CASE
           WHEN COALESCE(s.total_sales, 0) + COALESCE(ss.total_store_sales, 0) = 0 THEN 'No Sales'
           ELSE 'Sales Made'
       END AS sales_status
FROM CustomerCTE c
LEFT JOIN SalesCTE s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN StoreSalesCTE ss ON c.c_customer_sk = ss.ss_item_sk
LEFT JOIN InventoryCTE i ON c.c_current_addr_sk = i.inv_item_sk
WHERE c.rn <= 10
ORDER BY c.c_birth_year DESC, c.c_last_name;
