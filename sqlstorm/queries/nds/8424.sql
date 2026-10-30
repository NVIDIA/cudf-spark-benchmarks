
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_items_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
),
TopCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.cd_gender,
        cp.total_sales,
        cp.total_orders,
        cp.total_orders * 1.0 / NULLIF(cp.distinct_items_purchased, 0) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cp.cd_gender ORDER BY cp.total_sales DESC) AS rank
    FROM 
        CustomerPurchases cp
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.total_sales,
    tc.total_orders,
    tc.avg_order_value,
    ws.total_items_sold,
    ws.total_profit
FROM 
    TopCustomers tc
JOIN 
    WarehouseStats ws ON tc.total_sales > 1000
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.cd_gender, tc.total_sales DESC;
