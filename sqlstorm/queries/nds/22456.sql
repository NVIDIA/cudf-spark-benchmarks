
WITH  Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_state IS NOT NULL
), 
Sales_CTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_profit) AS total_profit,
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
Filtered_Products AS (
    SELECT i_item_sk, i_product_name, i_current_price
    FROM item
    WHERE i_current_price > (
        SELECT AVG(i_current_price)
        FROM item
        WHERE i_formulation IS NOT NULL
    )
), 
CustomerDetails AS (
    SELECT c.c_customer_sk, c.c_email_address, d.cd_marital_status, 
           (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS purchase_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_marital_status = 'S'
), 
Sales_Summary AS (
    SELECT p.i_item_sk, p.i_product_name,
           COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
           COALESCE(SUM(s.total_profit), 0) AS total_profit
    FROM Filtered_Products p
    LEFT JOIN Sales_CTE s ON p.i_item_sk = s.ws_item_sk
    GROUP BY p.i_item_sk, p.i_product_name
)
SELECT a.ca_city, a.ca_state, 
       c.c_email_address, 
       s.total_quantity_sold,
       s.total_profit,
       CASE 
           WHEN s.total_profit IS NULL THEN 'No Sales'
           WHEN s.total_profit < 1000 THEN 'Low Profit'
           WHEN s.total_profit >= 1000 THEN 'High Profit'
           ELSE 'Undefined'
       END AS profit_status
FROM Address_CTE a
JOIN CustomerDetails c ON c.c_customer_sk IN (
    SELECT sr_customer_sk 
    FROM store_returns 
    WHERE sr_returned_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
FULL OUTER JOIN Sales_Summary s ON a.ca_address_sk = CAST(s.i_item_sk AS INTEGER)
WHERE a.rn <= 10 AND c.purchase_count > (
       SELECT AVG(purchase_count) 
       FROM CustomerDetails 
       WHERE cd_marital_status IS NOT NULL
)
ORDER BY a.ca_city, s.total_profit DESC;
