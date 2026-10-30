
WITH RevenueByCustomer AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_revenue,
           COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_revenue,
           COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_revenue,
           COALESCE(SUM(sr.sr_net_loss), 0) + COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, 
           COUNT(DISTINCT c.c_customer_sk) AS num_customers,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(cd.cd_dep_count) AS max_dependencies
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
),
TopDemographics AS (
    SELECT cd.cd_demo_sk, 
           cd.avg_purchase_estimate,
           cd.max_dependencies,
           ROW_NUMBER() OVER (ORDER BY cd.avg_purchase_estimate DESC) AS ranking
    FROM CustomerDemographics cd
)
SELECT r.c_customer_id,
       r.total_web_revenue,
       r.total_catalog_revenue,
       r.total_store_revenue,
       r.total_return_loss,
       CASE 
           WHEN td.max_dependencies IS NULL THEN 'No Data'
           ELSE CONCAT('Max Dependencies:', td.max_dependencies)
       END AS demographics_info,
       COALESCE(td.avg_purchase_estimate, 0) AS avg_purchase_estimate
FROM RevenueByCustomer r
LEFT JOIN TopDemographics td ON r.c_customer_sk = td.cd_demo_sk
WHERE r.total_web_revenue > 1000
OR (r.total_catalog_revenue + r.total_store_revenue) >= 5000
ORDER BY r.total_web_revenue DESC, r.total_catalog_revenue DESC
LIMIT 50;
