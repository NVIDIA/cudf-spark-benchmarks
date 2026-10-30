
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        cs.sales_rank
    FROM CustomerSales cs
    WHERE cs.sales_rank <= 10
),
InventoryData AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    SUM(sd.total_sales) AS total_sales_per_customer,
    SUM(id.total_quantity) AS total_inventory,
    COALESCE(SUM(sd.total_sales) / NULLIF(SUM(id.total_quantity), 0), 0) AS sales_per_inventory_ratio,
    ROW_NUMBER() OVER (ORDER BY SUM(sd.total_sales) DESC) AS rank_by_sales
FROM TopCustomers tc
LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.ws_item_sk
LEFT JOIN InventoryData id ON sd.ws_item_sk = id.i_item_sk
GROUP BY tc.c_first_name, tc.c_last_name
HAVING SUM(sd.total_sales) > 1000
ORDER BY sales_per_inventory_ratio DESC;
