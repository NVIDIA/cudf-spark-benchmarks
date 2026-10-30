
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        NTILE(4) OVER (ORDER BY cs.total_sales) AS sales_quartile
    FROM 
        CustomerSales cs
),
HighValueCustomers AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.c_customer_sk,
        ss.total_sales,
        ss.order_count,
        ss.sales_quartile
    FROM 
        CustomerSales cs
    JOIN 
        SalesStats ss ON cs.c_customer_sk = ss.c_customer_sk
    WHERE 
        ss.sales_quartile = 4 
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    COALESCE(rr.r_reason_desc, 'No Reason') AS return_reason,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    store_returns sr ON hvc.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason rr ON sr.sr_reason_sk = rr.r_reason_sk
GROUP BY 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    rr.r_reason_desc
ORDER BY 
    hvc.total_sales DESC;
