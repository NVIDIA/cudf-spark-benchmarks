
WITH  PriceAnalysis AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales, 
           SUM(ws_ext_discount_amt) AS total_discount,
           COUNT(*) AS sales_count,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS item_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458821 AND 2458920
    GROUP BY ws_item_sk
),
CustomerDemographic AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           hd_income_band_sk 
    FROM customer_demographics 
    JOIN household_demographics ON hd_demo_sk = cd_demo_sk
    WHERE cd_gender IS NOT NULL AND cd_marital_status IS NOT NULL
),
DiscountSummary AS (
    SELECT ws_item_sk,
           CASE 
               WHEN total_discount = 0 THEN 'No Discount' 
               WHEN total_discount > 0 AND total_discount < 100 THEN 'Small Discount'
               ELSE 'Large Discount' 
           END AS discount_category
    FROM PriceAnalysis
),
QuantityAnalysis AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returns,
           COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns 
    GROUP BY sr_item_sk
),
FinalAnalysis AS (
    SELECT pa.ws_item_sk,
           pa.total_sales,
           pa.total_discount,
           pa.sales_count,
           ds.discount_category,
           qa.total_returns,
           qa.return_count
    FROM PriceAnalysis pa
    LEFT JOIN DiscountSummary ds ON pa.ws_item_sk = ds.ws_item_sk
    LEFT JOIN QuantityAnalysis qa ON pa.ws_item_sk = qa.sr_item_sk
)
SELECT ca.ca_city, 
       ca.ca_state,
       COALESCE(FinalAnalysis.total_sales, 0) AS total_sales, 
       COALESCE(FinalAnalysis.total_discount, 0) AS total_discount,
       COALESCE(FinalAnalysis.sales_count, 0) AS sales_count,
       COALESCE(FinalAnalysis.total_returns, 0) AS total_returns,
       COALESCE(FinalAnalysis.return_count, 0) AS return_count
FROM customer_address ca
LEFT JOIN FinalAnalysis ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer))
WHERE ca.ca_state IN (SELECT DISTINCT cd_marital_status FROM CustomerDemographic WHERE cd_gender = 'M')
ORDER BY total_sales DESC, total_discount DESC;
