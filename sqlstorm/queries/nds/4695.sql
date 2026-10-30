WITH Customer_Sales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001 AND d.d_month_seq IN (1, 2, 3) 
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Sales_Rank AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           cs.total_sales,
           cs.transaction_count,
           RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM Customer_Sales cs
),
Top_Customers AS (
    SELECT c.*,
           CASE 
               WHEN cc.cc_call_center_sk IS NOT NULL THEN 'Call Center'
               ELSE 'Store'
           END AS sales_channel
    FROM Sales_Rank c
    LEFT JOIN call_center cc ON c.c_customer_sk = cc.cc_call_center_sk
    WHERE c.sales_rank <= 10
)
SELECT tc.c_first_name,
       tc.c_last_name,
       tc.total_sales,
       tc.transaction_count,
       tc.sales_channel,
       CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
       COALESCE(tc.total_sales / NULLIF(tc.transaction_count, 0), 0) AS avg_sales_per_transaction
FROM Top_Customers tc
ORDER BY tc.total_sales DESC;