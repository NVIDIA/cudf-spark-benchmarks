
WITH address_summary AS (
    SELECT
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        COUNT(DISTINCT s_store_sk) AS store_count,
        SUM(COALESCE(ws_net_profit, 0)) AS total_profit
    FROM
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN store s ON ca.ca_state = s.s_state
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        ca_state
),
profit_ranking AS (
    SELECT
        ca_state,
        customer_count,
        store_count,
        total_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM
        address_summary
),
demographic_stats AS (
    SELECT
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM
        customer_demographics
    WHERE
        cd_marital_status = 'M' AND cd_dep_count > 0
    GROUP BY
        cd_gender
)
SELECT
    pr.ca_state, 
    pr.customer_count,
    pr.store_count,
    pr.total_profit,
    pr.profit_rank,
    ds.cd_gender,
    ds.demographic_count,
    ds.avg_purchase_estimate,
    ds.highest_credit_rating
FROM
    profit_ranking pr
FULL OUTER JOIN demographic_stats ds ON pr.customer_count > 0 AND ds.demographic_count > 0
WHERE
    (pr.store_count IS NULL OR pr.store_count > 5)
    AND (ds.avg_purchase_estimate > 100 OR ds.highest_credit_rating IS NULL)
ORDER BY
    pr.profit_rank, ds.cd_gender;
