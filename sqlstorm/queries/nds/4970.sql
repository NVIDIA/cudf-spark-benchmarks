
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy BETWEEN 5 AND 7
    )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM Customer_Sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    (SELECT COUNT(*) FROM customer) AS total_customers,
    (SELECT AVG(total_sales) FROM Top_Customers) AS avg_top_customer_sales
FROM Top_Customers tc
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC
LIMIT 10;
