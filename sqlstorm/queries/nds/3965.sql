WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
QualifiedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL 
        AND cs.order_count > 0
)
SELECT 
    q.c_first_name,
    q.c_last_name,
    q.total_sales,
    q.order_count,
    CASE 
        WHEN q.total_sales > 50000 THEN 'High Value'
        WHEN q.total_sales BETWEEN 20000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    QualifiedCustomers q
WHERE 
    q.rank <= 50
ORDER BY 
    q.total_sales DESC;