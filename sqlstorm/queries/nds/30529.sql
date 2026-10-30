
WITH  prior_sales AS (
    SELECT ws_item_sk, ws_order_number, ws_sales_price, ws_quantity, ws_sold_date_sk,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk < (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_year = 2023
    )
), daily_sales AS (
    SELECT d.d_date_sk, d.d_date, COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date_sk, d.d_date
), top_customers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender,
           COUNT(ws.ws_order_number) AS order_count, 
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ws.ws_sales_price * ws.ws_quantity) > 1000
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT ds.d_date, ds.total_sales, ds.order_count,
       tc.c_customer_id, tc.c_first_name, tc.c_last_name, tc.order_count AS customer_order_count,
       COALESCE(s.sale_change, 0) AS sale_change
FROM daily_sales ds
LEFT JOIN (
    SELECT ps.ws_item_sk, SUM(ps.ws_sales_price * ps.ws_quantity) AS sale_change
    FROM prior_sales ps
    WHERE ps.rn = 1
    GROUP BY ps.ws_item_sk
) s ON ds.d_date_sk = s.ws_item_sk
JOIN top_customers tc ON ds.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
WHERE COALESCE(s.sale_change, 0) > 0
ORDER BY ds.d_date DESC;
