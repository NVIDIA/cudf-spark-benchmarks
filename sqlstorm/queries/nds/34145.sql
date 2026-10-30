
WITH  SalesCTE AS (
    SELECT ss_item_sk, 
           SUM(ss_net_paid) AS total_sales,
           COUNT(DISTINCT ss_ticket_number) AS total_transactions,
           RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_item_sk
    HAVING SUM(ss_net_paid) > 0
),
ItemDetails AS (
    SELECT i.i_item_sk, 
           i.i_product_name, 
           i.i_brand, 
           i.i_current_price,
           COALESCE((SELECT COUNT(sr_item_sk) 
                     FROM store_returns 
                     WHERE sr_item_sk = i.i_item_sk), 0) AS total_returns
    FROM item i
)
SELECT id.i_item_sk, 
       id.i_product_name, 
       id.i_brand, 
       COALESCE(s.total_sales, 0) AS total_sales,
       COALESCE(s.total_transactions, 0) AS total_transactions,
       id.i_current_price,
       id.total_returns,
       CASE 
           WHEN s.sales_rank IS NOT NULL AND s.sales_rank <= 10 THEN 'Top Seller'
           ELSE 'Regular'
       END AS sales_category
FROM ItemDetails id
LEFT JOIN SalesCTE s ON id.i_item_sk = s.ss_item_sk
WHERE (id.total_returns > 0 OR s.total_sales > 1000) 
  AND (id.i_current_price BETWEEN 10 AND 100)
ORDER BY total_sales DESC, id.i_product_name
LIMIT 50;
