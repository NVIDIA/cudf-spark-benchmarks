
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_net_paid_inc_tax) AS max_net_paid
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 10500
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        cs.total_net_profit, 
        cs.total_orders
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_net_profit > 1000
    ORDER BY cs.total_net_profit DESC
    LIMIT 10
),
CustomerDetails AS (
    SELECT 
        tc.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM TopCustomers tc
    JOIN customer c ON tc.c_customer_id = c.c_customer_id
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    tc.total_net_profit,
    tc.total_orders
FROM CustomerDetails cd
JOIN TopCustomers tc ON cd.c_customer_id = tc.c_customer_id
ORDER BY tc.total_net_profit DESC;
