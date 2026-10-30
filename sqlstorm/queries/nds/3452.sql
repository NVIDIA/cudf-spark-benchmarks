
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        cs.average_order_value,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_web_sales > (SELECT AVG(total_web_sales) FROM CustomerSales)
),
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
WebReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt) AS total_web_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    hvc.order_count,
    hvc.average_order_value,
    COALESCE(sr.total_returns, 0) AS total_store_returns,
    COALESCE(sr.total_return_amount, 0) AS total_store_return_amount,
    COALESCE(wr.total_web_returns, 0) AS total_web_returns,
    COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    StoreReturns sr ON hvc.c_customer_sk = sr.sr_item_sk
LEFT JOIN 
    WebReturns wr ON hvc.c_customer_sk = wr.wr_item_sk
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_web_sales DESC;
