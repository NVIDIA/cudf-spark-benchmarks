
WITH RecursiveAddress AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state,
           CONCAT(CAST(ca_street_number AS STRING), ' ', ca_street_name) AS full_address,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_name) AS address_rank
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY') 
), 
CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_education_status, cd_purchase_estimate, 
           cd_credit_rating, COALESCE(cd_dep_count, 0) AS dep_count,
           (CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS is_female
    FROM customer_demographics
), 
CustomerWithAddress AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month,
           a.full_address, d.dep_count,
           (SELECT COUNT(*) FROM store_sales ss 
            WHERE ss.ss_customer_sk = c.c_customer_sk 
              AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim 
                                         WHERE d_year = 2001)) AS recent_store_purchases
    FROM customer c
    JOIN RecursiveAddress a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE c.c_birth_month IS NOT NULL
    AND a.address_rank <= 5 
)
SELECT cwa.full_address, cwa.dep_count, cwa.c_first_name, cwa.c_last_name, 
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       AVG(ws.ws_net_paid) AS avg_spent,
       COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_item_sk END) AS unique_items_purchased,
       ROW_NUMBER() OVER (PARTITION BY cwa.c_birth_month ORDER BY SUM(ws.ws_net_profit) DESC) AS birth_month_rank
FROM CustomerWithAddress cwa 
LEFT JOIN web_sales ws ON cwa.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY cwa.full_address, cwa.dep_count, cwa.c_first_name, cwa.c_last_name, cwa.c_birth_month
HAVING SUM(ws.ws_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales WHERE cs_sold_date_sk > 0)
ORDER BY birth_month_rank, total_profit DESC
LIMIT 10;
