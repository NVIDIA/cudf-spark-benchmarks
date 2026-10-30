
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        RankedSales.total_sales,
        RankedSales.order_count
    FROM 
        customer
    JOIN 
        RankedSales ON customer.c_customer_sk = RankedSales.ws_bill_customer_sk
    WHERE 
        RankedSales.sales_rank <= 10
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT tc.c_customer_id) AS customer_count,
    AVG(tc.total_sales) AS avg_sales
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC;
