WITH RecursiveSales AS (
    SELECT ss_item_sk, SUM(ss_net_paid) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY ss_item_sk
),
TopItems AS (
    SELECT i_item_sk, i_item_desc, i_current_price, i_brand, 
           (CASE 
                WHEN i_current_price < 20 THEN 'Low'
                WHEN i_current_price BETWEEN 20 AND 100 THEN 'Medium'
                ELSE 'High'
           END) AS price_category
    FROM item
    WHERE i_rec_start_date <= cast('2002-10-01' as date) AND 
          (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
),
CombinedSales AS (
    SELECT ti.i_item_sk, ti.i_item_desc, ti.i_current_price, ti.price_category,
           COALESCE(rs.total_sales, 0) AS total_sales
    FROM TopItems ti
    LEFT JOIN RecursiveSales rs 
    ON ti.i_item_sk = rs.ss_item_sk
),
FinalReport AS (
    SELECT cs.price_category, 
           COUNT(cs.i_item_sk) AS item_count,
           SUM(cs.total_sales) AS total_revenue,
           AVG(cs.total_sales) AS avg_sales
    FROM CombinedSales cs
    GROUP BY cs.price_category
)
SELECT fr.price_category,
       COALESCE(fr.item_count, 0) AS item_count,
       COALESCE(fr.total_revenue, 0) AS total_revenue,
       COALESCE(fr.avg_sales, 0) AS avg_sales
FROM FinalReport fr
UNION ALL
SELECT 'Overall' AS price_category, 
       COUNT(i.i_item_sk) AS item_count,
       SUM(COALESCE(cs.total_sales, 0)) AS total_revenue,
       AVG(COALESCE(cs.total_sales, 0)) AS avg_sales
FROM item i
LEFT JOIN CombinedSales cs
ON i.i_item_sk = cs.i_item_sk;