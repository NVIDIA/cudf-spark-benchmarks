
WITH CustomerSalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating 
    FROM 
        CustomerSalesData c
    JOIN 
        customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    WHERE 
        c.total_sales > (SELECT AVG(total_sales) FROM CustomerSalesData)
    ORDER BY 
        c.total_sales DESC
    LIMIT 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.cd_credit_rating,
        ws.warehouse_sales
    FROM 
        TopCustomers tc
    LEFT JOIN 
        WarehouseSales ws ON ws.warehouse_sales > 0
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    warehouse_sales IS NOT NULL
ORDER BY 
    warehouse_sales DESC;
