
WITH  TopCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk = (SELECT MAX(ss_info.ss_sold_date_sk) FROM store_sales ss_info)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(cs_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE cs.cs_sold_date_sk = (SELECT MAX(cs_info.cs_sold_date_sk) FROM catalog_sales cs_info)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerRanks AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, COALESCE(SUM(T.total_sales), 0) AS total_sales,
           RANK() OVER (ORDER BY COALESCE(SUM(T.total_sales), 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN (
        SELECT c_customer_sk, total_sales FROM TopCustomers
    ) T ON c.c_customer_sk = T.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopIncomeBands AS (
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM income_band ib
    LEFT JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
CombinedResults AS (
    SELECT cr.c_customer_sk, cr.c_first_name, cr.c_last_name, cr.total_sales, cr.sales_rank,
           ib.ib_lower_bound, ib.ib_upper_bound, COALESCE(ib.customer_count, 0) AS customer_count
    FROM CustomerRanks cr
    JOIN TopIncomeBands ib ON cr.sales_rank <= 10
)
SELECT c.c_first_name, c.c_last_name, r.total_sales, r.sales_rank, r.ib_lower_bound, r.ib_upper_bound, 
       CASE 
           WHEN r.total_sales IS NULL THEN 'No Sales'
           WHEN r.total_sales > 1000 THEN 'High Sales'
           ELSE 'Low Sales'
       END AS sales_category
FROM CombinedResults r
JOIN customer c ON r.c_customer_sk = c.c_customer_sk
WHERE c.c_birth_country IS NOT NULL AND r.customer_count >= 5
ORDER BY r.sales_rank, r.total_sales DESC;
