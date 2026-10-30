
WITH  CustomerReturns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
    HAVING SUM(cr_return_quantity) > 10
), CustomerSales AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           COUNT(ws_order_number) AS total_sales,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
), CustomerAnalytics AS (
    SELECT cs.customer_sk,
           COALESCE(cr.total_returned, 0) AS total_returned,
           cs.total_sales,
           cs.total_profit,
           CASE 
               WHEN cs.total_profit > 1000 THEN 'High Value'
               WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM CustomerSales cs
    LEFT JOIN CustomerReturns cr ON cs.customer_sk = cr.cr_returning_customer_sk
), StateDemographics AS (
    SELECT ca_state, 
           COUNT(DISTINCT c.c_customer_sk) AS total_customers,
           AVG(cd.cd_dep_count) AS avg_dependents,
           AVG(cd.cd_purchase_estimate) AS purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
)
SELECT 
    a.customer_value,
    b.total_customers,
    b.avg_dependents,
    b.purchase_estimate
FROM CustomerAnalytics a
JOIN StateDemographics b ON a.customer_sk IN (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('NY', 'CA', 'TX')
)
UNION
SELECT 
    'No Data' AS customer_value,
    b.total_customers,
    b.avg_dependents,
    b.purchase_estimate
FROM StateDemographics b
WHERE b.total_customers = 0
ORDER BY customer_value, total_customers DESC;
