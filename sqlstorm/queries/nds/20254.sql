WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' AND cd.cd_dep_count > 2 THEN 'Family'
            WHEN cd.cd_marital_status = 'S' AND cd.cd_dep_count = 0 THEN 'Single'
            ELSE 'Other'
        END AS customer_type,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count
), 
address_info AS (
    SELECT 
        DISTINCT ca.ca_address_sk, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(c.c_customer_sk) OVER (PARTITION BY ca.ca_state) AS customer_count_state
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'No Price'
            ELSE CAST(i.i_current_price AS VARCHAR(10))
        END AS current_price_str,
        COALESCE(i.i_current_price, 0) * 1.1 AS inflated_price
    FROM item i
    WHERE i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name,
    ai.ca_city,
    ai.ca_state,
    ds.total_net_paid,
    ds.rank_net_paid,
    id.i_item_desc,
    id.current_price_str,
    CASE 
        WHEN ds.rank_net_paid = 1 THEN 'Top Seller'
        ELSE 'Regular'
    END AS item_rank,
    ai.customer_count_state
FROM ranked_sales ds
JOIN customer_info ci ON ds.ws_item_sk = ci.c_customer_sk
JOIN address_info ai ON ci.c_customer_sk = ai.ca_address_sk
JOIN item_details id ON ds.ws_item_sk = id.i_item_sk
WHERE ai.customer_count_state > 5 
  AND (ci.total_orders > 0 OR ci.customer_type = 'Family')
  AND ci.cd_gender IS NOT NULL
ORDER BY total_net_paid DESC, ci.c_last_name ASC, ci.c_first_name ASC
LIMIT 100;