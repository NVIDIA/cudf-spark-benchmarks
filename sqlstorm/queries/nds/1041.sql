
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS gender_sales_rank,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS overall_sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT * FROM CustomerStats
    WHERE overall_sales_rank <= 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
FinalReport AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        ws.warehouse_sales,
        ws.total_orders,
        CASE 
            WHEN tc.total_sales IS NULL THEN 'No Sales'
            WHEN tc.total_sales > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM 
        TopCustomers tc
    LEFT JOIN 
        WarehouseSales ws ON tc.total_sales = ws.warehouse_sales
)
SELECT 
    *,
    COALESCE(total_orders, 0) AS orders_from_warehouse 
FROM 
    FinalReport
ORDER BY 
    total_sales DESC, c_last_name ASC;
