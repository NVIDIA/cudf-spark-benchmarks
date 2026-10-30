
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales
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
        c.c_customer_sk,
        MAX(c.total_web_sales + c.total_catalog_sales) AS total_sales,
        CASE 
            WHEN COUNT(c.c_customer_sk) > 5 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        CustomerSales c
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        * 
    FROM 
        SalesSummary
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ts.total_sales,
    ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS ranking
FROM 
    TopCustomers ts
JOIN 
    customer c ON ts.c_customer_sk = c.c_customer_sk
ORDER BY 
    ts.total_sales DESC;
