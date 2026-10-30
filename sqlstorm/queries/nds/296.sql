
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales,
        order_count,
        CASE 
            WHEN total_sales >= 5000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM CustomerSales
),
SalesTrend AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_year
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cv.customer_type,
    st.sales_amount,
    st.total_orders,
    ws.w_warehouse_name,
    ws.total_inventory
FROM HighValueCustomers cv
JOIN CustomerSales c ON c.c_customer_sk = cv.c_customer_sk
JOIN SalesTrend st ON st.sales_amount = (SELECT MAX(sales_amount) FROM SalesTrend)
RIGHT JOIN WarehouseStats ws ON ws.total_inventory > 10
ORDER BY cv.total_sales DESC, c.c_last_name ASC
LIMIT 100;
