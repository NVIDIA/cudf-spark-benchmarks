
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TopClients AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY c.total_spent DESC) AS rk
    FROM 
        CustomerOrders AS c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    tc.avg_order_value,
    d.d_date,
    w.w_warehouse_name
FROM 
    TopClients AS tc
JOIN 
    date_dim AS d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
LEFT JOIN 
    inventory AS inv ON inv.inv_item_sk = (SELECT i.i_item_sk FROM item AS i ORDER BY i.i_current_price DESC LIMIT 1)
LEFT JOIN 
    warehouse AS w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    tc.rk <= 10
    AND tc.total_spent IS NOT NULL
ORDER BY 
    tc.total_spent DESC;
