
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
OrderDetails AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS order_total,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_orders,
    od.order_total,
    od.item_count
FROM 
    TopCustomers tc
LEFT JOIN 
    OrderDetails od ON tc.total_orders = od.item_count
WHERE 
    tc.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
ORDER BY 
    tc.total_web_sales DESC;
