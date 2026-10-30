
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_current_cdemo_sk,
           SUM(COALESCE(ws_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0) + COALESCE(ss_ext_sales_price, 0)) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS online_orders,
           COUNT(DISTINCT cs_order_number) AS catalog_orders,
           COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM customer c
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk
),
DemographicStats AS (
    SELECT cd.cd_demo_sk,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
           SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk
),
IncomeBands AS (
    SELECT ib.ib_income_band_sk,
           CASE 
               WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL THEN 
                   CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
               ELSE 'Unknown' 
           END AS income_band_range
    FROM income_band ib
)
SELECT cs.c_customer_sk,
       cs.total_sales,
       cs.online_orders,
       cs.catalog_orders,
       cs.store_orders,
       ds.avg_purchase_estimate,
       ds.female_count,
       ds.male_count,
       ib.income_band_range
FROM CustomerSales cs
JOIN DemographicStats ds ON cs.c_current_cdemo_sk = ds.cd_demo_sk
LEFT JOIN IncomeBands ib ON ds.cd_demo_sk = ib.ib_income_band_sk
WHERE cs.total_sales > 5000
  AND (ds.avg_purchase_estimate IS NOT NULL AND ds.avg_purchase_estimate > 1000)
ORDER BY cs.total_sales DESC
LIMIT 100;
