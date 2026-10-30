
WITH  SalesHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_net_profit) IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_profit) IS NOT NULL
),
AggregatedSales AS (
    SELECT cd_gender,
           cd_marital_status,
           COUNT(DISTINCT c_customer_id) AS customer_count,
           SUM(total_net_profit) AS net_profit
    FROM SalesHierarchy
    GROUP BY cd_gender, cd_marital_status
),
RankedSales AS (
    SELECT cd_gender,
           cd_marital_status,
           customer_count,
           net_profit,
           RANK() OVER (ORDER BY net_profit DESC) AS profit_rank
    FROM AggregatedSales
)
SELECT r.cd_gender,
       r.cd_marital_status,
       r.customer_count,
       r.net_profit,
       CASE WHEN r.profit_rank <= 5 THEN 'Top 5' ELSE 'Below Top 5' END AS ranking_category
FROM RankedSales r
WHERE r.customer_count > 50
ORDER BY r.net_profit DESC;
