
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 1000
),
SalesDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnDetails AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(sr.sr_ticket_number) AS returns_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    tc.c_customer_sk,
    CONCAT(csd.c_first_name, ' ', csd.c_last_name) AS customer_name,
    tc.total_sales,
    sd.total_profit,
    rd.total_returns,
    CASE 
        WHEN rd.total_returns IS NULL THEN 'No Returns'
        WHEN rd.total_returns > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status
FROM 
    TopCustomers tc
JOIN 
    SalesDetails sd ON tc.c_customer_sk = sd.c_customer_sk
JOIN 
    customer csd ON tc.c_customer_sk = csd.c_customer_sk
LEFT JOIN 
    ReturnDetails rd ON rd.sr_customer_sk = tc.c_customer_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
