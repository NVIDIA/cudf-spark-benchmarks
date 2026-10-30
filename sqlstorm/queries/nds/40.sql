
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.total_quantity,
        cp.total_spent,
        cp.purchase_count,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM CustomerPurchases cp
    JOIN customer c ON cp.c_customer_id = c.c_customer_id
    WHERE cp.total_spent > 1000
),
TopCustomers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, HVC.total_spent
    FROM HighValueCustomers HVC
    JOIN customer c ON HVC.c_customer_id = c.c_customer_id
    WHERE HVC.customer_rank <= 10
),
StoreStats AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT 
    T.c_customer_id,
    T.c_first_name,
    T.c_last_name,
    T.total_spent,
    SS.s_store_name,
    SS.total_sold,
    SS.total_profit,
    CASE 
        WHEN SS.total_profit IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    'Customer Total: ' || T.total_spent || ' | Store Total Sold: ' || COALESCE(SS.total_sold, 0) AS combined_info
FROM TopCustomers T
JOIN StoreStats SS ON T.c_customer_id IN (
    SELECT c.c_customer_id 
    FROM web_sales ws 
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
)
ORDER BY T.total_spent DESC, SS.total_profit DESC;
