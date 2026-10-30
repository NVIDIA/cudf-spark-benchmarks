
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        cs.total_quantity,
        DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
),
MostProfitableItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
),
SalesByWarehouse AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_warehouse_profit,
        SUM(ws.ws_quantity) AS total_warehouse_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_warehouse_sk
),
AggregateMetrics AS (
    SELECT 
        MAX(cs.total_net_profit) AS max_customer_profit,
        MIN(cs.total_net_profit) AS min_customer_profit,
        AVG(cs.total_net_profit) AS avg_customer_profit,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM 
        CustomerSales cs
    JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk, 
    tc.total_orders,
    tc.total_net_profit,
    tc.total_quantity,
    mpi.total_net_profit AS most_profitable_item_net_profit,
    si.i_item_desc AS most_profitable_item_desc,
    sw.total_warehouse_profit,
    am.max_customer_profit,
    am.min_customer_profit,
    am.avg_customer_profit,
    am.total_sales_profit
FROM 
    TopCustomers tc
JOIN 
    MostProfitableItems mpi ON mpi.total_net_profit = (SELECT MAX(total_net_profit) FROM MostProfitableItems)
JOIN 
    item si ON mpi.ws_item_sk = si.i_item_sk
JOIN 
    SalesByWarehouse sw ON sw.total_warehouse_profit = (SELECT MAX(total_warehouse_profit) FROM SalesByWarehouse)
JOIN 
    AggregateMetrics am ON 1=1
ORDER BY 
    tc.rank;
