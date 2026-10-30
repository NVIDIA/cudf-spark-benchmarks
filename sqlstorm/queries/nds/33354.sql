
WITH  sales_rank AS (
    SELECT ws_item_sk, 
           ws_sales_price, 
           ws_net_paid, 
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM web_sales
),
recent_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           AVG(ws_net_paid) AS avg_net_paid
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
address_info AS (
    SELECT ca_state, 
           COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca 
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_state
),
combined_sales AS (
    SELECT s.ss_item_sk, 
           ss_store_sk, 
           ss_net_profit, 
           ss_net_paid_inc_tax
    FROM store_sales s
    LEFT JOIN store_returns r ON s.ss_item_sk = r.sr_item_sk 
    WHERE r.sr_return_quantity IS NULL 
    UNION ALL
    SELECT cs.cs_item_sk, 
           cs_call_center_sk, 
           cs_net_profit, 
           cs_net_paid_inc_tax
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk 
    WHERE cr.cr_return_quantity IS NULL
),
final_summary AS (
    SELECT c.c_first_name, 
           c.c_last_name, 
           ai.ca_state, 
           sr.rank, 
           rs.total_quantity, 
           rs.avg_net_paid, 
           cs.ss_net_profit
    FROM customer c
    JOIN address_info ai ON ai.customer_count > 100 
    JOIN sales_rank sr ON sr.ws_item_sk = c.c_current_cdemo_sk
    JOIN recent_sales rs ON rs.ws_item_sk = c.c_current_hdemo_sk
    JOIN combined_sales cs ON cs.ss_item_sk = c.c_current_addr_sk
)
SELECT COUNT(*) AS summary_count, 
       AVG(avg_net_paid) AS average_net_paid, 
       SUM(total_quantity) AS total_units_sold
FROM final_summary
WHERE rank <= 5 
AND ss_net_profit > 1000 
GROUP BY ca_state
ORDER BY summary_count DESC;
