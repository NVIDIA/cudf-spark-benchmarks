WITH recent_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_ext_sales_price) AS total_sales 
    FROM web_sales 
    WHERE ws_sold_date_sk IN (SELECT d_date_sk 
                               FROM date_dim 
                               WHERE d_date >= cast('2002-10-01' as date) - INTERVAL '3 MONTH')
    GROUP BY ws_item_sk
), high_income_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           h.hd_income_band_sk 
    FROM customer c
    JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    WHERE h.hd_income_band_sk IS NOT NULL
), item_details AS (
    SELECT i.i_item_sk, 
           i.i_item_desc, 
           i.i_brand, 
           ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ws_ext_sales_price) DESC) AS brand_rank 
    FROM item i 
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_brand
)

SELECT r.c_first_name, 
       r.c_last_name, 
       id.i_item_desc, 
       id.i_brand, 
       COALESCE(s.total_quantity, 0) AS total_quantity, 
       COALESCE(s.total_sales, 0) AS total_sales,
       CASE 
           WHEN s.total_sales > 1000 THEN 'High Spender'
           WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Spender'
           ELSE 'Low Spender'
       END AS spending_category
FROM high_income_customers r
LEFT JOIN recent_sales s ON r.c_customer_sk = s.ws_item_sk
JOIN item_details id ON s.ws_item_sk = id.i_item_sk
WHERE id.brand_rank <= 5
ORDER BY r.c_first_name, r.c_last_name, total_sales DESC;