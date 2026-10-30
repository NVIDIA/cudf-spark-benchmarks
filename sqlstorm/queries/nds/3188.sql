
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
),
ReturnData AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
StoreSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS store_total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(ss.store_total_sales, 0) AS store_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(hvc.total_sales, 0) AS high_value_sales,
    COALESCE(hvc.total_orders, 0) AS high_value_orders,
    hvc.sales_rank
FROM 
    store s
LEFT JOIN 
    StoreSales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    ReturnData rd ON s.s_store_sk = rd.sr_store_sk
LEFT JOIN 
    HighValueCustomers hvc ON hvc.total_sales > 5000
ORDER BY 
    store_sales DESC, total_returns DESC, high_value_sales DESC;
