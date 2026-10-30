
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
)
SELECT 
    tc.rank,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    tc.avg_order_value,
    wa.w_warehouse_name,
    SUM(i.inv_quantity_on_hand) AS total_inventory
FROM 
    TopCustomers tc
JOIN 
    inventory i ON i.inv_warehouse_sk IN (SELECT w.w_warehouse_sk FROM warehouse w WHERE w.w_warehouse_name LIKE 'Main%')
JOIN 
    warehouse wa ON wa.w_warehouse_sk = i.inv_warehouse_sk
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.rank, tc.c_first_name, tc.c_last_name, tc.total_spent, tc.order_count, tc.avg_order_value, wa.w_warehouse_name
ORDER BY 
    tc.rank;
