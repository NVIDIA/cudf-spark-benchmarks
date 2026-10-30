
WITH  CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY c.c_preferred_cust_flag ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450005 
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender,
           ss.total_sales, ss.total_orders,
           CASE WHEN ss.total_sales IS NULL THEN 'No Sales' ELSE 'Has Sales' END AS sales_status
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT cs.c_first_name, cs.c_last_name, cs.cd_gender, COALESCE(cs.total_sales, 0) AS total_sales,
       COALESCE(cs.total_orders, 0) AS total_orders, cs.sales_status,
       CASE 
           WHEN cs.total_sales IS NOT NULL AND cs.total_orders IS NOT NULL AND cs.total_orders > 10 
           THEN 'Premium Customer'
           WHEN (cs.total_orders = 0 OR (cs.total_sales IS NULL AND cs.cd_gender = 'M')) 
           THEN 'Potential Lead'
           ELSE 'General Customer'
       END AS customer_tier,
       (SELECT COUNT(DISTINCT sr_ticket_number) 
        FROM store_returns 
        WHERE sr_customer_sk = cs.c_customer_sk AND sr_return_quantity > 0) AS return_count
FROM CustomerSales cs
LEFT JOIN store s ON EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = cs.c_customer_sk)
WHERE COALESCE(cs.total_sales, 0) > (SELECT AVG(total_sales) FROM SalesSummary) 
  OR cs.sales_status = 'No Sales' 
  OR cs.total_orders IS NULL
ORDER BY customer_tier ASC, total_sales DESC;
