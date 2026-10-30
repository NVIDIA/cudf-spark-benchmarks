
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesSummary AS (
    SELECT 
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        AVG(web_order_count) AS avg_web_orders,
        AVG(catalog_order_count) AS avg_catalog_orders
    FROM 
        CustomerSales
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cs.total_web_sales,
        cs.total_catalog_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY 
        (cs.total_web_sales + cs.total_catalog_sales) DESC
    LIMIT 10
) 
SELECT 
    T.customer_name,
    T.total_web_sales,
    T.total_catalog_sales,
    S.total_web_sales AS overall_web_sales,
    S.total_catalog_sales AS overall_catalog_sales,
    S.avg_web_orders,
    S.avg_catalog_orders
FROM 
    TopCustomers T
CROSS JOIN 
    SalesSummary S;
