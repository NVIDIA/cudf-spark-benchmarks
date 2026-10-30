
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(DISTINCT ss.ss_store_sk) AS unique_stores,
        NTILE(4) OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS net_profit_quartile
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk, d.d_year
), demographic_groups AS (
    SELECT
        cd.cd_demo_sk,
        MAX(CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END) AS gender,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_college_count) AS college_dependents
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk
), address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
), promo_stats AS (
    SELECT
        p.p_promo_sk,
        SUM(ws.ws_net_profit) AS promo_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT
    cs.c_customer_sk,
    cs.total_net_profit,
    cs.total_transactions,
    cs.avg_quantity,
    cs.unique_stores,
    dg.gender,
    dg.total_dependents,
    dg.avg_purchase_estimate,
    dg.college_dependents,
    ai.customer_count,
    ps.promo_net_profit,
    ps.order_count,
    CASE 
        WHEN cs.net_profit_quartile = 1 THEN 'Low Profit'
        WHEN cs.net_profit_quartile = 2 THEN 'Medium Profit'
        WHEN cs.net_profit_quartile = 3 THEN 'High Profit'
        ELSE 'Very High Profit'
    END AS profit_category
FROM customer_stats cs
LEFT JOIN demographic_groups dg ON cs.c_current_cdemo_sk = dg.cd_demo_sk
LEFT JOIN address_info ai ON cs.c_customer_sk = ai.customer_count
LEFT JOIN promo_stats ps ON cs.c_current_cdemo_sk = ps.p_promo_sk
WHERE (cs.total_net_profit IS NOT NULL AND cs.total_transactions > 5)
  OR (ai.customer_count > 10 AND ps.order_count > 2)
ORDER BY cs.total_net_profit DESC, dg.avg_purchase_estimate DESC;
