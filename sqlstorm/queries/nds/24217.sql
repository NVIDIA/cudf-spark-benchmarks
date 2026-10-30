
WITH  AddressHierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS addr_row_num
    FROM customer_address
    WHERE ca_city IS NOT NULL
), 
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_current_addr_sk, cd.cd_gender, 
           cd.cd_marital_status, cd.cd_purchase_estimate,
           COALESCE(NULLIF(cd.cd_credit_rating, 'Unknown'), 'Not Specified') AS credit_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
SalesData AS (
    SELECT ws.ws_item_sk, ws.ws_sales_price, ws.ws_quantity, 
           SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
           CASE WHEN ws.ws_sales_price > 50 THEN 'High Value' ELSE 'Low Value' END AS sales_value_category
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_item_sk, cs.cs_sales_price, cs.cs_quantity,
           SUM(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_item_sk) AS total_sales,
           CASE WHEN cs.cs_sales_price > 50 THEN 'High Value' ELSE 'Low Value' END AS sales_value_category
    FROM catalog_sales cs
), 
RankedCustomers AS (
    SELECT ci.c_customer_sk,
           ROW_NUMBER() OVER (ORDER BY SUM(sd.total_sales) DESC) AS customer_rank
    FROM CustomerInfo ci
    JOIN SalesData sd ON ci.c_current_addr_sk = sd.ws_item_sk
    GROUP BY ci.c_customer_sk
)

SELECT ah.ca_city, ah.ca_state, 
       COUNT(DISTINCT rc.c_customer_sk) AS unique_customers, 
       MAX(CASE WHEN rc.customer_rank <= 10 THEN 'Top Customer' ELSE 'Regular Customer' END) AS customer_status,
       SUM(sd.total_sales) AS overall_sales, 
       SUM(CASE WHEN sd.sales_value_category = 'High Value' THEN sd.ws_quantity ELSE 0 END) AS high_value_sales_quantity,
       COUNT(CASE WHEN sd.ws_sales_price IS NULL THEN 1 END) AS null_sales_price_count
FROM AddressHierarchy ah
LEFT JOIN RankedCustomers rc ON ah.addr_row_num = rc.customer_rank
LEFT JOIN SalesData sd ON rc.c_customer_sk = sd.ws_item_sk
WHERE ah.ca_state IS NOT NULL
GROUP BY ah.ca_city, ah.ca_state
HAVING SUM(sd.total_sales) > 10000 OR MAX(CASE WHEN rc.customer_rank <= 10 THEN 'Top Customer' ELSE 'Regular Customer' END) = 'Top Customer'
ORDER BY overall_sales DESC, ah.ca_city;
