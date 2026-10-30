
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        cs.last_purchase_date,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS rn
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_sk = cs.c_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_orders,
    tc.last_purchase_date,
    SUBSTRING(tc.c_first_name, 1, 3) || ' ' || tc.c_last_name AS customer_alias
FROM 
    TopCustomers tc
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_web_sales DESC;
