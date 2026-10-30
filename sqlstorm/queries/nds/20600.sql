
WITH  PriceTrend AS (
    SELECT ws_item_sk, 
           ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 365
),
SalesAnalysis AS (
    SELECT item.i_item_sk, 
           item.i_item_id, 
           item.i_category, 
           AVG(PriceTrend.ws_sales_price) AS avg_price,
           SUM(COALESCE(web_sales.ws_quantity, 0)) AS total_sold,
           COUNT(DISTINCT web_sales.ws_order_number) AS total_orders
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    LEFT JOIN PriceTrend ON web_sales.ws_item_sk = PriceTrend.ws_item_sk
    GROUP BY item.i_item_sk, item.i_item_id, item.i_category
),
CustomerInsights AS (
    SELECT c.c_customer_sk,
           SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
           SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 100
    GROUP BY c.c_customer_sk
)
SELECT sa.i_item_id,
       sa.avg_price,
       sa.total_sold,
       ci.male_count,
       ci.female_count,
       CASE 
           WHEN sa.total_orders > 100 THEN 'High Demand' 
           WHEN sa.total_orders BETWEEN 50 AND 100 THEN 'Moderate Demand'
           ELSE 'Low Demand'
       END AS demand_level,
       CASE 
           WHEN ci.male_count IS NULL THEN 'No Male Customers'
           WHEN ci.female_count IS NULL THEN 'No Female Customers'
           ELSE 'Mixed Gender'
       END AS customer_gender_analysis
FROM SalesAnalysis sa
LEFT JOIN CustomerInsights ci ON sa.i_item_sk = ci.c_customer_sk
WHERE sa.avg_price IS NOT NULL 
      AND sa.total_sold > 0
ORDER BY demand_level DESC, sa.avg_price DESC
LIMIT 100;
