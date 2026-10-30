
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM item i 
    JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE sd.total_sales > 10000
),
WarehouseStatistics AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT s.s_store_id) AS store_count,
        SUM(s.s_number_employees) AS total_employees 
    FROM warehouse w
    JOIN store s ON w.w_warehouse_sk = s.s_store_sk
    GROUP BY w.w_warehouse_id
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        COUNT(ws.ws_order_number) AS order_count
    FROM RankedCustomers rc
    JOIN web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE rc.rnk <= 5
    GROUP BY rc.c_customer_sk, rc.c_first_name, rc.c_last_name
)
SELECT 
    wh.w_warehouse_id AS warehouse_id,
    wh.store_count,
    wh.total_employees,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    tc.c_first_name,
    tc.c_last_name,
    tc.order_count
FROM WarehouseStatistics wh
FULL OUTER JOIN HighValueItems ti ON wh.store_count > 0
INNER JOIN TopCustomers tc ON wh.store_count = (SELECT MAX(store_count) FROM WarehouseStatistics)
ORDER BY wh.w_warehouse_id, ti.total_sales DESC, tc.order_count DESC;
