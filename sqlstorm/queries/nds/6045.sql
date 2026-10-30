WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_purchase_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459215 AND 2459218 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM CustomerStats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.order_count > 0
)
SELECT 
    tc.rank,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    cs.total_quantity,
    cs.order_count,
    cs.avg_purchase_value
FROM TopCustomers tc
JOIN CustomerStats cs ON tc.c_customer_sk = cs.c_customer_sk
WHERE tc.rank <= 10 
ORDER BY tc.rank;