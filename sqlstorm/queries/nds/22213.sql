
WITH  SalesAnalysis AS (
    SELECT ss_item_sk, 
           SUM(ss_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions,
           DENSE_RANK() OVER (ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_item_sk
), 
HighValueSales AS (
    SELECT sa.ss_item_sk, sa.total_sales, sa.total_transactions 
    FROM SalesAnalysis sa
    WHERE sa.sales_rank <= 100 
      AND sa.total_sales > (SELECT AVG(total_sales) * 1.2 FROM SalesAnalysis)
), 
CustomerInfo AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           cd.cd_gender,
           cd.cd_marital_status,
           COALESCE(cd.cd_credit_rating, 'Not Rated') AS credit_rating,
           hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)

SELECT ci.customer_name, 
       ci.cd_gender,
       ci.credit_rating,
       SUM(hv.total_sales) AS total_spent,
       COUNT(DISTINCT hv.total_transactions) AS number_of_high_value_items,
       CASE 
           WHEN COUNT(DISTINCT hv.total_transactions) > 10 THEN 'Frequent Shopper'
           WHEN COUNT(DISTINCT hv.total_transactions) = 0 THEN 'Casual Shopper'
           ELSE 'Occasional Shopper'
       END AS shopper_type
FROM CustomerInfo ci
JOIN HighValueSales hv ON ci.c_customer_sk = hv.ss_item_sk 
GROUP BY ci.customer_name, ci.cd_gender, ci.credit_rating
HAVING SUM(hv.total_sales) > (SELECT AVG(total_sales) FROM HighValueSales)
ORDER BY total_spent DESC;
