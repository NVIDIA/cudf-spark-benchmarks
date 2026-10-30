
WITH ranked_promotions AS (
    SELECT p.p_promo_id, 
           p.p_discount_active, 
           p.p_start_date_sk, 
           p.p_end_date_sk, 
           ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY p.p_end_date_sk DESC) AS promo_rank
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
), 
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_birth_year, 
           cd.cd_gender, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_birth_year, cd.cd_gender
),
high_rollers AS (
    SELECT ci.c_customer_sk, 
           ci.cd_gender, 
           ci.c_birth_year, 
           ci.total_net_profit,
           RANK() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_net_profit DESC) AS rank_profit
    FROM customer_info ci
    WHERE ci.total_net_profit > (
        SELECT AVG(total_net_profit) 
        FROM customer_info
    )
)
SELECT 
    cu.c_customer_id, 
    cu.c_first_name, 
    cu.c_last_name,
    ci.cd_gender,
    ci.total_net_profit,
    CASE 
        WHEN ci.total_net_profit IS NULL THEN 'No Purchases'
        ELSE 'Active Shopper'
    END AS customer_status,
    r.p_promo_id AS relevant_promo
FROM customer cu
LEFT JOIN customer_info ci ON cu.c_customer_sk = ci.c_customer_sk
LEFT JOIN ranked_promotions r ON r.promo_rank = 1
WHERE (ci.total_net_profit > 1000 OR ci.cd_gender = 'F')
  AND ci.c_birth_year IS NOT NULL
  AND r.p_discount_active = 'Y'
ORDER BY ci.total_net_profit DESC, cu.c_last_name ASC
LIMIT 100
OFFSET 10;
