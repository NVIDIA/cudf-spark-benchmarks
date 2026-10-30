
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_spent,
        cp.total_orders,
        cp.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM CustomerPurchase cp
    JOIN customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE cp.total_spent > 1000
),
TopProducts AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_spent,
    hvc.total_orders,
    hvc.avg_order_value,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    tp.i_item_sk,
    tp.i_item_desc,
    tp.total_sold,
    tp.total_revenue
FROM HighValueCustomers hvc
CROSS JOIN TopProducts tp
ORDER BY hvc.total_spent DESC, tp.total_revenue DESC
LIMIT 50;
