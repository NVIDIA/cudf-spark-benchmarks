
WITH  OrderHierarchy AS (
    SELECT cs_order_number, cs_item_sk, cs_quantity, cs_sales_price,
           ROW_NUMBER() OVER (PARTITION BY cs_order_number ORDER BY cs_item_sk) AS rn
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT max(cs_sold_date_sk) FROM catalog_sales)
),
CustomerReturns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_amount) AS total_return_amount,
           COUNT(cr_returning_customer_sk) AS total_returns
    FROM catalog_returns
    WHERE cr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY cr_returning_customer_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_profit) AS total_sales_profit,
           COUNT(ws_order_number) AS total_orders,
           MAX(ws_ship_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
)
SELECT COALESCE(c.c_customer_id, 'Unknown') AS customer_id,
       s.total_sales_profit,
       r.total_return_amount,
       CASE 
           WHEN s.total_sales_profit IS NULL THEN 'No Sales'
           WHEN r.total_returns = 0 THEN 'No Returns'
           ELSE 'Sales vs Returns'
       END AS status,
       (SELECT COUNT(*) FROM OrderHierarchy oh WHERE oh.cs_order_number = s.ws_bill_customer_sk) AS order_count,
       (SELECT COUNT(*) FROM CustomerReturns cr WHERE cr.cr_returning_customer_sk = c.c_customer_sk) AS return_count
FROM customer c
LEFT JOIN SalesSummary s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
WHERE c.c_current_addr_sk IN (
    SELECT ca_address_sk 
    FROM customer_address 
    WHERE ca_state = 'NY'
)
AND r.total_return_amount IS NOT NULL
ORDER BY customer_id;
