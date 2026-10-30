
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_web_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount
FROM 
    TopCustomers tc
LEFT JOIN 
    StoreReturns sr ON tc.c_customer_sk = sr.sr_item_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;
