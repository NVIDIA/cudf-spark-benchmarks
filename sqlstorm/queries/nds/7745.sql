
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_net_profit,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
),
RankedWarehouseSales AS (
    SELECT 
        ws.w_warehouse_sk,
        ws.total_quantity_sold,
        ws.total_revenue,
        RANK() OVER (ORDER BY ws.total_revenue DESC) AS revenue_rank
    FROM 
        WarehouseSales ws
)
SELECT 
    tc.c_customer_sk,
    tc.total_orders,
    tc.total_net_profit,
    rws.w_warehouse_sk,
    rws.total_quantity_sold,
    rws.total_revenue
FROM 
    TopCustomers tc
JOIN 
    RankedWarehouseSales rws ON tc.profit_rank = rws.revenue_rank
WHERE 
    tc.profit_rank <= 10 AND rws.revenue_rank <= 10
ORDER BY 
    tc.total_net_profit DESC, rws.total_revenue DESC;
