
WITH  income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           CASE WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown' 
                ELSE CONCAT('Income Band: ', ib_lower_bound, ' - ', ib_upper_bound)
           END AS income_band_desc
    FROM income_band
), customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, 
           CASE 
               WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'S' THEN 'Single Male'
               WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' THEN 'Single Female'
               WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Male'
               WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Female'
               ELSE 'Other'
           END AS marital_info,
           ROW_NUMBER() OVER (PARTITION BY d.d_year, cd.cd_gender ORDER BY c.c_customer_sk) AS row_num,
           COUNT(*) OVER (PARTITION BY d.d_year, cd.cd_gender) AS total_per_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
), unique_customers AS (
    SELECT DISTINCT c.c_customer_sk, CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           ci.marital_info, ci.row_num, ci.total_per_gender
    FROM customer c
    JOIN customer_info ci ON c.c_customer_sk = ci.c_customer_sk
    WHERE ci.row_num <= 5
), product_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           AVG(ws_net_profit) AS avg_profit,
           (SUM(ws_ext_sales_price) - SUM(ws_coupon_amt)) AS net_revenue
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 365
    GROUP BY ws_item_sk
), sales_ranked AS (
    SELECT ps.*, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM product_sales ps
), returned_items AS (
    SELECT cr_item_sk, SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    GROUP BY cr_item_sk
), item_with_returns AS (
    SELECT ps.*, COALESCE(ri.total_returned, 0) AS total_returned
    FROM sales_ranked ps
    LEFT JOIN returned_items ri ON ps.ws_item_sk = ri.cr_item_sk
)
SELECT ci.full_name, ci.marital_info, ib.income_band_desc,
       iw.ws_item_sk, iw.total_sales, iw.net_revenue, iw.avg_profit,
       iw.total_returned,
       CASE
           WHEN iw.total_returned > 0 THEN 'Returned Items Exist'
           ELSE 'No Returns'
       END AS return_status
FROM unique_customers ci
JOIN income_brackets ib ON ci.total_per_gender BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN item_with_returns iw ON ci.c_customer_sk = iw.ws_item_sk
ORDER BY ci.marital_info, iw.net_revenue DESC
LIMIT 10 OFFSET 10;
