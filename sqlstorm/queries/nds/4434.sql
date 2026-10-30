WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_by_spending
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_orders,
        cs.total_spent
    FROM CustomerStats cs
    WHERE cs.rank_by_spending <= 10
),
WebSalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_paid_inc_tax) > 1000 
)

SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_orders,
    tc.total_spent,
    wss.total_web_sales,
    COALESCE(wss.total_web_sales, 0) AS web_sales_with_fallback
FROM TopCustomers tc
LEFT JOIN WebSalesSummary wss ON wss.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
ORDER BY tc.total_spent DESC;