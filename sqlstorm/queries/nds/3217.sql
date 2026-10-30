
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 29 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        cs.total_orders,
        cs.avg_net_paid,
        cs.profit_rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.profit_rank <= 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    tc.total_orders,
    tc.avg_net_paid,
    COALESCE((SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA'), 0) AS total_stores_ca,
    CASE 
        WHEN tc.total_orders > 0 THEN ROUND((tc.total_profit / tc.total_orders), 2)
        ELSE NULL
    END AS avg_profit_per_order
FROM
    TopCustomers tc
LEFT JOIN
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE
    cd.cd_gender = 'F' AND
    cd.cd_marital_status = 'M' AND
    cd.cd_credit_rating IN (SELECT r.r_reason_id FROM reason r WHERE r.r_reason_desc LIKE '%discount%')
ORDER BY
    tc.total_profit DESC;
