
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL OR ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, 
           ib.ib_lower_bound + 100,
           ib.ib_upper_bound + 100
    FROM income_band ib
    JOIN IncomeRanges ir ON ib.ib_income_band_sk = ir.ib_income_band_sk
    WHERE ib.ib_lower_bound < 1000
), 
CustomerStats AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
               WHEN cd.cd_purchase_estimate BETWEEN 1 AND 100 THEN 'Low'
               WHEN cd.cd_purchase_estimate BETWEEN 101 AND 500 THEN 'Medium'
               WHEN cd.cd_purchase_estimate > 500 THEN 'High'
           END AS purchase_estimate_category,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
), 
SalesSummary AS (
    SELECT cs.cs_order_number,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           SUM(cs.cs_ext_tax) AS total_tax,
           COUNT(cs.cs_item_sk) AS item_count,
           MAX(cs.cs_sold_date_sk) AS last_sale_date
    FROM catalog_sales cs
    GROUP BY cs.cs_order_number
)
SELECT cs.c_first_name, 
       cs.c_last_name, 
       cs.purchase_estimate_category,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.total_tax, 0) AS total_tax,
       ss.item_count,
       ss.last_sale_date,
       (SELECT COUNT(*) 
        FROM store_sales ss2 
        WHERE ss2.ss_customer_sk = cs.c_customer_sk 
        AND ss2.ss_sold_date_sk IS NOT NULL) AS store_sales_count,
       CASE 
           WHEN ss.last_sale_date IS NULL THEN 'No Sales'
           ELSE 'Has Sales'
       END AS sales_status
FROM CustomerStats cs
LEFT JOIN SalesSummary ss ON cs.total_orders > 10 AND cs.c_customer_sk = ss.cs_order_number
WHERE cs.cd_gender IN ('M', 'F')
AND (cs.cd_marital_status IS NULL OR cs.cd_marital_status = 'S')
ORDER BY total_sales DESC NULLS LAST
LIMIT 100;
