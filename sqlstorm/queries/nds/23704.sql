
WITH RecursiveCustomerCTE AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL
), 
AggregatedSales AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MAX(ws_ship_date_sk) AS last_order_date
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
StoreSalesParticipation AS (
    SELECT ss_customer_sk,
           SUM(ss_net_profit) AS net_profit,
           COUNT(DISTINCT ss_ticket_number) AS store_order_count
    FROM store_sales
    GROUP BY ss_customer_sk
), 
CustomerFullSummary AS (
    SELECT cust.c_customer_sk,
           cust.c_first_name,
           cust.c_last_name,
           COALESCE(web.total_sales, 0) AS total_web_sales,
           COALESCE(web.order_count, 0) AS total_web_orders,
           COALESCE(store.net_profit, 0) AS total_store_net_profit,
           COALESCE(store.store_order_count, 0) AS total_store_orders,
           CASE 
               WHEN web.total_sales > 0 AND store.net_profit > 0 THEN 'Both' 
               WHEN web.total_sales > 0 THEN 'Web Only' 
               WHEN store.net_profit > 0 THEN 'Store Only' 
               ELSE 'None' 
           END AS sales_participation
    FROM RecursiveCustomerCTE cust
    LEFT JOIN AggregatedSales web ON cust.c_customer_sk = web.ws_bill_customer_sk
    LEFT JOIN StoreSalesParticipation store ON cust.c_customer_sk = store.ss_customer_sk
)
SELECT cs.c_customer_sk,
       cs.c_first_name,
       cs.c_last_name,
       cs.total_web_sales,
       cs.total_web_orders,
       cs.total_store_net_profit,
       cs.total_store_orders,
       cs.sales_participation,
       CASE 
           WHEN cs.total_web_sales > 1000 THEN 'High Value'
           WHEN cs.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS web_sales_value,
       CASE 
           WHEN cs.total_store_net_profit > 1000 THEN 'High Profit'
           ELSE 'Low Profit' 
       END AS store_sales_value
FROM CustomerFullSummary cs
WHERE cs.sales_participation != 'None'
AND (cs.total_web_sales - cs.total_store_net_profit) > 0
ORDER BY cs.total_web_sales DESC, cs.total_store_net_profit DESC
LIMIT 10;
