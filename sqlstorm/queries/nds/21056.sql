
WITH  address_tree AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS state_rank
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
customer_ranking AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS gender_rank,
           ROW_NUMBER() OVER (ORDER BY c.c_current_cdemo_sk) AS customer_row
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_aggregates AS (
    SELECT i.i_item_sk, i.i_item_id, SUM(ws.ws_quantity) AS total_sales,
           AVG(ws.ws_sales_price) AS avg_price
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
store_info AS (
    SELECT s_store_sk, s_store_name, 
           COALESCE(SUM(CASE WHEN ss.ss_sold_date_sk = d.d_date_sk THEN ss.ss_net_paid END), 0) AS store_sales_total
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s_store_sk, s_store_name
),
final_report AS (
    SELECT 
        atr.ca_address_id,
        cr.c_customer_sk,
        cr.c_first_name || ' ' || cr.c_last_name AS full_name,
        atr.ca_city,
        atr.ca_state,
        ia.total_sales, 
        ia.avg_price,
        si.store_sales_total,
        DENSE_RANK() OVER (PARTITION BY atr.ca_state ORDER BY ia.total_sales DESC) AS sales_rank
    FROM address_tree atr
    JOIN customer_ranking cr ON cr.customer_row <= 10
    JOIN item_aggregates ia ON ia.total_sales IS NOT NULL
    LEFT JOIN store_info si ON si.s_store_sk = cr.c_customer_sk 
    WHERE (ia.avg_price BETWEEN 10 AND 100 
           OR ia.total_sales IS NULL) 
      AND (atr.ca_state = 'CA' 
           OR (atr.ca_state IS NULL AND ia.total_sales IS NOT NULL))
)
SELECT *
FROM final_report
WHERE (sales_rank BETWEEN 1 AND 5) 
ORDER BY ca_state, total_sales DESC, full_name ASC;
