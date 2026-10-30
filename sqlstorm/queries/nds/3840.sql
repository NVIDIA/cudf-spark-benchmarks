
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
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
        cs.num_orders,
        cs.rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.rank <= 10
),
AverageOrderValue AS (
    SELECT 
        c.c_customer_sk,
        AVG(os.total_amount) AS avg_order_value
    FROM (
        SELECT 
            ws.ws_order_number,
            SUM(ws.ws_ext_sales_price) AS total_amount,
            ws.ws_bill_customer_sk
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_order_number, ws.ws_bill_customer_sk
    ) os
    JOIN 
        customer c ON os.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.num_orders,
    aov.avg_order_value,
    CASE 
        WHEN tc.total_web_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    TopCustomers tc
LEFT JOIN 
    AverageOrderValue aov ON tc.c_customer_sk = aov.c_customer_sk
ORDER BY 
    tc.total_web_sales DESC;

