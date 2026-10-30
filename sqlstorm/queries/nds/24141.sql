
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        cs.total_profit,
        cs.total_orders,
        (SELECT AVG(total_profit) FROM CustomerSales) AS avg_profit
    FROM 
        customer c
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_profit > (SELECT MAX(total_profit) * 0.5 FROM CustomerSales) 
        OR cs.total_profit < (SELECT MIN(total_profit) FROM CustomerSales WHERE total_profit > 0)
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(ss.ss_item_sk) AS item_count,
        SUM(ss.ss_net_profit) AS total_net_profit,
        LEAD(SUM(ss.ss_net_profit)) OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS next_warehouse_profit
    FROM 
        warehouse w
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    ws.w_warehouse_sk,
    ws.item_count,
    ws.total_net_profit,
    CASE 
        WHEN ws.total_net_profit IS NULL THEN 'No Profit Data'
        WHEN ws.total_net_profit > (SELECT AVG(total_net_profit) FROM WarehouseStats) THEN 'Above Average Profit'
        ELSE 'Below Average Profit'
    END AS profit_status,
    CASE 
        WHEN ws.next_warehouse_profit IS NOT NULL THEN 'Next Warehouse Profit Exists'
        ELSE 'No Next Warehouse Profit'
    END AS next_profit_status
FROM 
    TopCustomers tc
JOIN 
    WarehouseStats ws ON tc.total_orders = ws.item_count
WHERE 
    (tc.total_profit IS NOT NULL OR ws.total_net_profit IS NOT NULL)
    AND (tc.total_orders > 10 OR ws.item_count < 5)
ORDER BY 
    tc.total_profit DESC, 
    ws.item_count ASC
LIMIT 100;
