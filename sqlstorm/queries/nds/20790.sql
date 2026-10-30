
WITH  RecentReturns AS (
    SELECT cr_returning_customer_sk, 
           cr_returned_date_sk, 
           cr_item_sk, 
           cr_return_quantity, 
           ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_returned_date_sk DESC) AS rn
    FROM catalog_returns
), 
HighValueReturns AS (
    SELECT rr.cr_returning_customer_sk,
           SUM(rr.cr_return_quantity) AS total_return_quantity,
           COUNT(DISTINCT rr.cr_item_sk) AS unique_items_returned
    FROM RecentReturns rr
    WHERE rr.rn <= 10
    GROUP BY rr.cr_returning_customer_sk
), 
CustomerDetails AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_credit_rating,
           COALESCE(hd.hd_income_band_sk, 0) AS hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
CustomerReturns AS (
    SELECT cd.c_customer_sk, 
           cd.c_first_name || ' ' || cd.c_last_name AS full_name, 
           COALESCE(hv.total_return_quantity, 0) AS return_quantity, 
           hv.unique_items_returned,
           CASE 
               WHEN cd.cd_gender = 'M' AND hv.total_return_quantity > 5 THEN 'Frequent Male Returner'
               WHEN cd.cd_gender = 'F' AND hv.unique_items_returned > 3 THEN 'Frequent Female Returner'
               ELSE 'Occasional Returner' 
           END AS returner_type
    FROM CustomerDetails cd
    LEFT JOIN HighValueReturns hv ON cd.c_customer_sk = hv.cr_returning_customer_sk
)
SELECT cr.full_name, 
       cr.return_quantity, 
       cr.unique_items_returned, 
       cr.returner_type,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
       SUM(ws.ws_net_profit) AS total_profit
FROM CustomerReturns cr
LEFT JOIN web_sales ws ON cr.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY cr.full_name, cr.return_quantity, cr.unique_items_returned, cr.returner_type
HAVING (SUM(ws.ws_net_profit) > 1000 OR cr.return_quantity > 5) 
ORDER BY total_profit DESC, cr.return_quantity DESC
LIMIT 50
OFFSET 5;
