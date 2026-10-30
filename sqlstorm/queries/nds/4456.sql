
WITH CustomerSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(COALESCE(ss.ss_net_paid, 0)) AS total_store_sales,
           SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
           SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales,
           COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_transaction_count,
           COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_transaction_count,
           COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_transaction_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT *, 
           RANK() OVER (ORDER BY total_store_sales + total_web_sales + total_catalog_sales DESC) AS sales_rank
    FROM CustomerSales
)
SELECT r.c_customer_sk, 
       r.c_first_name, 
       r.c_last_name, 
       r.total_store_sales, 
       r.total_web_sales, 
       r.total_catalog_sales,
       CASE 
           WHEN r.sales_rank <= 10 THEN 'Top 10' 
           ELSE 'Others' 
       END AS sales_category,
       (SELECT COUNT(DISTINCT i.i_item_sk) 
        FROM item i 
        WHERE i.i_current_price BETWEEN 10 AND 100 
          AND (SELECT COUNT(*) 
               FROM store_sales ss 
               WHERE ss.ss_item_sk = i.i_item_sk) > 5
        ) AS eligible_items
FROM RankedSales r
WHERE r.total_store_sales > 1000 
   OR (r.total_web_sales > 500 AND r.web_transaction_count > 5)
ORDER BY r.sales_rank;
