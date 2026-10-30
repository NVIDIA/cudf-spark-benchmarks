
WITH ActiveCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS GenderRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND (c.c_preferred_cust_flag = 'Y' OR cd.cd_marital_status = 'M')
),
SalesData AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, 
           ws.ws_net_paid, ws.ws_net_profit,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS ProfitRank
    FROM web_sales ws
    WHERE ws.ws_sales_price > 10.00 AND (ws.ws_net_paid IS NOT NULL OR ws.ws_net_profit IS NULL)
),
AggregateSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM SalesData ws
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 100 AND SUM(ws.ws_net_profit) IS NOT NULL
)
SELECT ac.c_first_name, ac.c_last_name, 
       CASE 
           WHEN ac.GenderRank <= 10 THEN CONCAT('Top ', ac.cd_gender, ' Customers')
           ELSE 'Others'
       END AS Customer_Category,
       ag.total_quantity, ag.total_profit
FROM ActiveCustomers ac
LEFT JOIN AggregateSales ag ON ac.c_customer_sk = ag.ws_item_sk
WHERE EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_customer_sk = ac.c_customer_sk
    AND c.c_current_addr_sk IS NOT NULL
    AND c.c_email_address LIKE '%@example.com'
) OR ag.total_profit > (SELECT AVG(total_profit) FROM AggregateSales)
ORDER BY ac.c_last_name ASC, ac.c_first_name DESC;
