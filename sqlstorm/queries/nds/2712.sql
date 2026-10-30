
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
), HighSpendingCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    h.c_first_name, 
    h.c_last_name, 
    h.total_sales,
    CASE 
        WHEN h.total_sales > 5000 THEN 'High Spender'
        WHEN h.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'Low Spender' 
    END AS spending_category,
    (SELECT COUNT(DISTINCT ws.ws_order_number) 
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = h.c_customer_sk) AS web_order_count,
    (SELECT COUNT(DISTINCT cs.cs_order_number) 
     FROM catalog_sales cs 
     WHERE cs.cs_bill_customer_sk = h.c_customer_sk) AS catalog_order_count
FROM 
    HighSpendingCustomers h
ORDER BY 
    h.total_sales DESC;
