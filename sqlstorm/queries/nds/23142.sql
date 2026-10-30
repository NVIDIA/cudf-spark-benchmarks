
WITH  address_explore AS (
    SELECT ca_address_sk, ca_country, ca_state, ca_city, ca_zip, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_country IS NOT NULL
), promo_analysis AS (
    SELECT p.p_promo_name, SUM(CASE 
        WHEN p.p_start_date_sk < p.p_end_date_sk 
             THEN 1 
             ELSE 0 END) AS active_promos,
        COUNT(DISTINCT p.p_promo_sk) AS total_promotions
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name
), sales_data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid) AS total_paid,
           AVG(ws_net_profit) AS avg_net_profit,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_day_name NOT IN ('Saturday', 'Sunday')
    )
    GROUP BY ws_bill_customer_sk
), complex_query AS (
    SELECT a.ca_city, s.total_paid, p.active_promos,
           CASE 
               WHEN s.total_orders > 10 THEN 'High Volume'
               WHEN s.total_orders BETWEEN 5 AND 10 THEN 'Medium Volume'
               ELSE 'Low Volume'
           END AS sales_category
    FROM address_explore a
    LEFT JOIN sales_data s ON a.ca_address_sk = s.ws_bill_customer_sk
    JOIN promo_analysis p ON p.active_promos > 0
    WHERE a.rn <= 5 AND a.ca_state IN ('CA', 'NY')
)
SELECT DISTINCT sales_category, ca_city, total_paid 
FROM complex_query
ORDER BY sales_category DESC, total_paid DESC
LIMIT 10;
