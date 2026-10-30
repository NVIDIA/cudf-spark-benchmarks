
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > 0
),
SalesDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS web_total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
CombinedSales AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_customer_id,
        tc.total_sales,
        tc.total_orders,
        COALESCE(sd.web_total_sales, 0) AS web_total_sales,
        COALESCE(sd.web_total_orders, 0) AS web_total_orders
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesDetails sd ON tc.c_customer_sk = sd.c_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.total_orders,
    cs.web_total_sales,
    cs.web_total_orders,
    COALESCE(cs.total_sales, 0) + COALESCE(cs.web_total_sales, 0) AS combined_sales,
    CASE 
        WHEN cs.total_sales IS NULL AND cs.web_total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 10000 THEN 'High Value Customer'
        WHEN cs.total_sales > 0 THEN 'Regular Customer'
        ELSE 'Potential Customer'
    END AS customer_status
FROM 
    CombinedSales cs
WHERE 
    cs.total_orders > 5 OR cs.web_total_orders > 2
ORDER BY 
    combined_sales DESC;
