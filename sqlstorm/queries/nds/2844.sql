
WITH Customer_Info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_credit_rating, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_credit_rating IS NOT NULL
),
Sales_Data AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) as total_net_profit, COUNT(ws_order_number) as order_count
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL AND ws_net_profit > 0
    GROUP BY ws_bill_customer_sk
),
Returns_Data AS (
    SELECT cr_returning_customer_sk, SUM(cr_net_loss) as total_net_loss, COUNT(cr_order_number) as return_count
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returning_customer_sk
),
Combined_Sales_Returns AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.ca_city, ci.ca_state,
           COALESCE(sd.total_net_profit, 0) as total_net_profit, 
           COALESCE(rd.total_net_loss, 0) as total_net_loss,
           sd.order_count, rd.return_count
    FROM Customer_Info ci
    LEFT JOIN Sales_Data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN Returns_Data rd ON ci.c_customer_sk = rd.cr_returning_customer_sk
)
SELECT c.c_first_name || ' ' || c.c_last_name AS full_name,
       c.ca_city, c.ca_state,
       c.total_net_profit, c.order_count,
       c.total_net_loss, c.return_count,
       (c.total_net_profit - c.total_net_loss) AS net_gain_loss,
       CASE 
           WHEN (c.order_count - c.return_count) > 0 THEN 'Profitable'
           ELSE 'Unprofitable' 
       END AS profit_status
FROM Combined_Sales_Returns c
WHERE (c.total_net_profit - c.total_net_loss) > 0
ORDER BY net_gain_loss DESC
LIMIT 50;
