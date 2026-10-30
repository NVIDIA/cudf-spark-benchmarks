WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ws.ws_sold_date_sk BETWEEN 2451815 AND 2454620 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
WarehouseSummary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    ws.w_warehouse_id,
    ws.order_count,
    ws.total_profit
FROM 
    TopCustomers tc
JOIN 
    WarehouseSummary ws ON tc.total_orders > 5
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, ws.total_profit DESC;