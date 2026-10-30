
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_moy = 12)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        cs.total_net_profit,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name,
    tc.last_name,
    tc.total_net_profit,
    COALESCE(
        (SELECT MAX(s.sm_ship_mode_id) 
         FROM ship_mode s
         LEFT JOIN web_sales ws ON s.sm_ship_mode_sk = ws.ws_ship_mode_sk
         WHERE ws.ws_bill_customer_sk = tc.customer_sk), 'No Ship Mode') AS max_ship_mode,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = tc.customer_sk 
     AND ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                                 FROM date_dim d 
                                 WHERE d.d_year = 2023 
                                 AND d.d_moy IN (11, 12))
     ) AS store_sales_count
FROM TopCustomers tc
WHERE tc.rank <= 10
ORDER BY tc.total_net_profit DESC;
