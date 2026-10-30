
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        CASE 
            WHEN COALESCE(SUM(ws.ws_net_paid), 0) > 0 THEN 'Web'
            WHEN COALESCE(SUM(ss.ss_net_paid), 0) > 0 THEN 'Store'
            ELSE 'None'
        END AS purchase_channel
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_web_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_store_sales,
    tc.sales_rank,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Other Customers'
    END AS customer_category
FROM 
    TopCustomers tc
WHERE 
    tc.total_web_sales > 1000 
    OR tc.total_store_sales > 1000
ORDER BY 
    customer_category DESC, sales_rank;
