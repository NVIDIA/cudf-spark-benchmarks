
WITH AddressDetails AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip, count(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip
),
DemographicsData AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
           COUNT(cd.cd_dep_count) AS total_dependents
    FROM customer_demographics cd
    WHERE cd.cd_gender IS NOT NULL AND cd.cd_purchase_estimate > 0
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_sales_price) AS total_sales_value,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_weekend = 'Y'
    )
    GROUP BY ws.ws_item_sk
),
CustomerSales AS (
    SELECT s.ss_customer_sk, s.ss_item_sk, SUM(s.ss_quantity) AS quantity_sold,
           SUM(s.ss_net_profit) AS net_profit
    FROM store_sales s
    WHERE s.ss_item_sk IN (SELECT inv.inv_item_sk FROM inventory inv WHERE inv.inv_quantity_on_hand < 0)
    GROUP BY s.ss_customer_sk, s.ss_item_sk
),
FinalAnalysis AS (
    SELECT ad.ca_city, ad.ca_state, ad.ca_zip,
           SUM(sd.total_net_profit) AS total_sales_net_profit,
           MAX(dd.total_purchase_estimate) AS max_purchase_estimate,
           dd.total_dependents
    FROM AddressDetails ad
    JOIN CustomerSales cs ON ad.customer_count > 0
    LEFT JOIN DemographicsData dd ON cs.ss_customer_sk = dd.cd_demo_sk
    LEFT JOIN SalesData sd ON cs.ss_item_sk = sd.ws_item_sk
    GROUP BY ad.ca_city, ad.ca_state, ad.ca_zip, dd.total_dependents
)
SELECT DISTINCT fa.ca_city, fa.ca_state, fa.ca_zip,
       fa.total_sales_net_profit,
       fa.max_purchase_estimate,
       CASE 
           WHEN fa.total_sales_net_profit > 1000 THEN 'High Profit'
           WHEN fa.total_sales_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
           ELSE 'Low Profit'
       END AS profit_category
FROM FinalAnalysis fa
WHERE fa.total_sales_net_profit IS NOT NULL
   OR fa.max_purchase_estimate IS NULL
   AND fa.total_dependents > 1
ORDER BY fa.ca_city, fa.ca_state;
