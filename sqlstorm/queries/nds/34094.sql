
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), HighProfitItems AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        sales.total_profit
    FROM item
    JOIN SalesCTE sales ON item.i_item_sk = sales.ws_item_sk
    WHERE sales.rn = 1 AND sales.total_profit IS NOT NULL
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    hp.i_item_desc,
    hp.total_profit,
    CASE 
        WHEN hp.total_profit > 1000 THEN 'High'
        WHEN hp.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM customer c 
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN HighProfitItems hp ON c.c_customer_sk IN (
    SELECT sr_customer_sk 
    FROM store_returns 
    WHERE sr_return_quantity > 0 AND sr_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 20)
)
WHERE c.c_birth_month = 10 
AND ca.ca_state IN ('CA', 'NY')
ORDER BY hp.total_profit DESC, c.c_last_name ASC
LIMIT 50;
