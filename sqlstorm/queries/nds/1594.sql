
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        cd_gender,
        cd_marital_status,
        total_sales,
        order_count
    FROM CustomerSales
    WHERE sales_rank <= 10
),
InventoryData AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.order_count,
    COALESCE(i.total_inventory, 0) AS total_inventory
FROM TopCustomers tc
LEFT JOIN InventoryData i ON tc.c_customer_id = i.i_item_id
WHERE tc.total_sales > (
    SELECT AVG(total_sales)
    FROM TopCustomers
) OR tc.cd_marital_status = 'M'
ORDER BY tc.total_sales DESC;
