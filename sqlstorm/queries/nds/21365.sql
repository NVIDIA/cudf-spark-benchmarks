
WITH Recursive_CTE AS (
    SELECT ca_address_sk, ca_city, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_country = 'USA'
), Sales_CTE AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_ext_sales_price - ws_ext_discount_amt) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           COUNT(DISTINCT CASE WHEN ws_net_profit > 0 THEN ws_order_number END) AS profitable_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), Demographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, 
           cd_purchase_estimate, 
           COALESCE(cd_dep_count, 0) AS dependents,
           COALESCE(cd_dep_employed_count, 0) AS employed_dependents
    FROM customer_demographics
    WHERE cd_gender = 'F' AND cd_marital_status = 'M'
), Address_Sales AS (
    SELECT ca.ca_city, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer_address ca
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    GROUP BY ca.ca_city
), High_Spenders AS (
    SELECT sd.ws_bill_customer_sk, sd.total_sales, sd.order_count,
           DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM Sales_CTE sd
    WHERE sd.total_sales > (SELECT AVG(total_sales) FROM Sales_CTE)
), Income_Summary AS (
    SELECT hd.hd_income_band_sk, 
           AVG(sd.total_sales) AS average_sales
    FROM household_demographics hd
    JOIN High_Spenders sd ON hd.hd_demo_sk = sd.ws_bill_customer_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT ra.ca_city, 
       COALESCE(ah.order_count, 0) AS total_orders,
       COALESCE(ah.total_sales, 0) AS sales_value,
       i.average_sales AS average_income_sales,
       COALESCE(od.dependents, 0) AS dependent_count,
       CASE WHEN ah.total_sales < 1000 THEN 'Low' 
            WHEN ah.total_sales BETWEEN 1000 AND 5000 THEN 'Medium' 
            ELSE 'High' END AS sales_category
FROM Recursive_CTE ra
LEFT JOIN Address_Sales ah ON ra.ca_city = ah.ca_city
LEFT JOIN Income_Summary i ON ah.order_count > 0
LEFT JOIN Demographics od ON od.cd_demo_sk = ra.ca_address_sk
WHERE ra.rn = (SELECT MAX(rn) FROM Recursive_CTE) 
  AND (ah.total_sales IS NOT NULL OR i.average_sales IS NOT NULL)
ORDER BY ra.ca_city, sales_category;
