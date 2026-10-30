
WITH  SalesCTE AS (
    SELECT ws_item_sk, 
           SUM(ws_net_profit) AS total_profit, 
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 0
),
CustomerReturns AS (
    SELECT sr_item_sk,
           COUNT(DISTINCT sr_ticket_number) AS return_count,
           SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
),
AddressDetails AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state, 
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address
    JOIN customer ON ca_address_sk = c_current_addr_sk
    GROUP BY ca_address_sk, ca_city, ca_state
    HAVING COUNT(DISTINCT c_customer_sk) > 100
)
SELECT COALESCE(SALES.ws_item_sk, RETURNS.sr_item_sk) AS item_sk,
       SALES.total_profit,
       SALES.order_count,
       RETURNS.return_count,
       RETURNS.total_return_amt,
       ADDR.ca_city,
       ADDR.ca_state,
       ADDR.customer_count,
       (SALES.total_profit - COALESCE(RETURNS.total_return_amt, 0)) AS net_profit_after_returns
FROM SalesCTE AS SALES
FULL OUTER JOIN CustomerReturns AS RETURNS ON SALES.ws_item_sk = RETURNS.sr_item_sk
JOIN AddressDetails AS ADDR ON SALES.ws_item_sk = ADDR.ca_address_sk
WHERE (SALES.rank <= 10 OR RETURNS.return_count >= 5)
ORDER BY net_profit_after_returns DESC, item_sk;
