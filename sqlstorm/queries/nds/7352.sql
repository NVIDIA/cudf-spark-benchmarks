
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
TopCustomers AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerPurchase
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spent,
    tc.total_orders,
    w.w_warehouse_name,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, tc.cd_marital_status, tc.total_spent, tc.total_orders, w.w_warehouse_name
ORDER BY 
    total_spent DESC;
