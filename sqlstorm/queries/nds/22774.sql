
WITH  sales_ranks AS (
    SELECT ws_item_sk,
           ws_order_number,
           ws_sales_price,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
address_info AS (
    SELECT ca_address_sk, 
           ca_city, 
           ca_state,
           COUNT(c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_address_sk, ca_city, ca_state
),
marital_statistics AS (
    SELECT cd_marital_status,
           COUNT(c_customer_sk) AS marital_count,
           SUM(cd_dep_count) AS total_dependents
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_marital_status IN ('M', 'S')
    GROUP BY cd_marital_status
),
final_report AS (
    SELECT ai.ca_city,
           ai.ca_state,
           ms.cd_marital_status,
           ms.marital_count,
           ms.total_dependents,
           sr.ws_item_sk,
           sr.ws_order_number,
           sr.ws_sales_price
    FROM address_info ai
    LEFT JOIN marital_statistics ms ON ai.customer_count > ms.marital_count
    LEFT JOIN sales_ranks sr ON ms.marital_count IS NOT NULL
    WHERE ai.customer_count < (SELECT AVG(customer_count) FROM address_info)
      AND EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_quantity > 10 
                  AND ss.ss_item_sk = sr.ws_item_sk)
)
SELECT fr.ca_city,
       fr.ca_state,
       fr.cd_marital_status,
       fr.marital_count,
       fr.total_dependents,
       COALESCE(SUM(fr.ws_sales_price), 0) AS total_sales,
       COUNT(DISTINCT fr.ws_order_number) AS unique_orders,
       CASE 
           WHEN COUNT(DISTINCT fr.ws_order_number) > 5 THEN 'High'
           ELSE 'Low'
       END AS order_volume_category
FROM final_report fr
GROUP BY fr.ca_city, fr.ca_state, fr.cd_marital_status, fr.marital_count, fr.total_dependents
HAVING COUNT(fr.ca_city) IS NOT NULL
ORDER BY total_sales DESC, fr.ca_city ASC NULLS LAST;
