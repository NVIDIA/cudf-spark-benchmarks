
WITH CustomerStats AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_ordered,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cs.total_net_profit,
        cs.total_orders,
        cs.unique_items_ordered,
        cs.avg_purchase_estimate,
        cs.max_dependents,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank_profit
    FROM
        CustomerStats cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.total_orders,
    tc.unique_items_ordered,
    tc.avg_purchase_estimate,
    tc.max_dependents
FROM 
    TopCustomers tc
WHERE 
    tc.rank_profit <= 10
ORDER BY 
    tc.total_net_profit DESC;
