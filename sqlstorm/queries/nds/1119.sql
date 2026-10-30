
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
SalesWithDemographics AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        td.cd_gender,
        td.cd_marital_status,
        tc.total_sales,
        tc.total_orders,
        CASE 
            WHEN td.cd_purchase_estimate > 500 THEN 'High Value'
            WHEN td.cd_purchase_estimate BETWEEN 200 AND 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        TopCustomers tc
    LEFT JOIN 
        customer_demographics td ON tc.c_customer_sk = td.cd_demo_sk
)
SELECT 
    swd.c_customer_sk,
    swd.c_first_name || ' ' || swd.c_last_name AS full_name,
    swd.total_sales,
    swd.total_orders,
    swd.customer_value,
    COALESCE((SELECT AVG(total_sales) FROM CustomerSales WHERE total_sales IS NOT NULL), 0) AS average_sales,
    CASE 
        WHEN swd.total_sales > (SELECT AVG(total_sales) FROM CustomerSales WHERE total_sales IS NOT NULL) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    SalesWithDemographics swd
ORDER BY 
    swd.total_sales DESC;
