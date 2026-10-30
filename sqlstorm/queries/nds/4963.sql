
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    LEFT JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
SalesPerformance AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cp.total_spent,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchase cp
    JOIN 
        customer c ON cp.c_customer_sk = c.c_customer_sk
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchase)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ws.w_warehouse_name,
    ws.total_inventory,
    sp.total_profit,
    sp.total_sales
FROM 
    TopCustomers tc
JOIN 
    WarehouseStats ws ON ws.total_inventory > (SELECT AVG(total_inventory) FROM WarehouseStats)
LEFT JOIN 
    SalesPerformance sp ON sp.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
