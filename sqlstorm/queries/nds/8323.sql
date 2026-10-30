
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity_sold,
        cs.total_sales_value,
        CASE 
            WHEN cs.total_sales_value > 10000 THEN 'High Value'
            WHEN cs.total_sales_value BETWEEN 5000 AND 10000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        CustomerSales cs
),
TopCustomers AS (
    SELECT 
        s.c_customer_sk,
        s.total_quantity_sold,
        s.total_sales_value,
        s.customer_segment,
        ROW_NUMBER() OVER (PARTITION BY s.customer_segment ORDER BY s.total_sales_value DESC) AS rank
    FROM 
        SalesSummary s
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    tc.total_quantity_sold,
    tc.total_sales_value,
    tc.customer_segment
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
WHERE 
    tc.rank <= 5
ORDER BY 
    tc.customer_segment, tc.total_sales_value DESC;
