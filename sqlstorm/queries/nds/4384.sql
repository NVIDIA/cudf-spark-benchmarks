
WITH CustomerSalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cte.c_customer_sk,
        cte.c_first_name,
        cte.c_last_name,
        cte.total_web_sales,
        RANK() OVER (ORDER BY cte.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSalesCTE cte
    WHERE 
        cte.total_web_sales > (
            SELECT AVG(total_web_sales) 
            FROM CustomerSalesCTE
        )
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_web_sales,
    CASE 
        WHEN hvc.total_web_sales IS NULL THEN 'No Sales'
        WHEN hvc.total_web_sales < 1000 THEN 'Low Value'
        ELSE 'High Value'
    END AS customer_value,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = hvc.c_customer_sk
     GROUP BY ss.ss_customer_sk) AS store_transaction_count,
    COALESCE((SELECT SUM(sr_return_amt) 
              FROM store_returns sr 
              WHERE sr.sr_customer_sk = hvc.c_customer_sk), 0) AS total_store_returns
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    customer_address ca ON hvc.c_customer_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    hvc.sales_rank;
