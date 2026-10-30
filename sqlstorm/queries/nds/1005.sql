
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ss.ss_ext_sales_price) AS total_store_sales,
           SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesComparison AS (
    SELECT cs.c_customer_sk, 
           cs.c_first_name, 
           cs.c_last_name,
           COALESCE(cs.total_store_sales, 0) AS store_sales,
           COALESCE(ws.total_web_sales, 0) AS web_sales,
           CASE 
               WHEN COALESCE(cs.total_store_sales, 0) > COALESCE(ws.total_web_sales, 0) THEN 'Store'
               WHEN COALESCE(cs.total_store_sales, 0) < COALESCE(ws.total_web_sales, 0) THEN 'Web'
               ELSE 'Equal'
           END AS preferred_channel
    FROM CustomerSales cs
    FULL OUTER JOIN CustomerSales ws ON cs.c_customer_sk = ws.c_customer_sk
    WHERE (cs.total_store_sales IS NOT NULL OR ws.total_web_sales IS NOT NULL)
)
SELECT cc.c_customer_sk,
       cc.c_first_name,
       cc.c_last_name,
       cc.store_sales,
       cc.web_sales,
       cc.preferred_channel,
       DENSE_RANK() OVER (ORDER BY store_sales DESC) AS store_sales_rank,
       DENSE_RANK() OVER (ORDER BY web_sales DESC) AS web_sales_rank
FROM SalesComparison cc
WHERE cc.store_sales > 1000 OR cc.web_sales > 1000
ORDER BY cc.store_sales DESC, cc.web_sales DESC;
