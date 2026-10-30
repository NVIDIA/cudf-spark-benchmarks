
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        cs.unique_items,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
FrequentReturners AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.total_orders,
    hvc.unique_items,
    COALESCE(fr.return_count, 0) AS return_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    FrequentReturners fr ON hvc.c_customer_sk = fr.sr_customer_sk
WHERE 
    hvc.sales_rank <= 100
ORDER BY 
    hvc.total_sales DESC;
