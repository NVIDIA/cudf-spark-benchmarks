
WITH  Sales_Rankings AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_within_customer
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sr.total_sales,
        sr.rank_within_customer
    FROM 
        Sales_Rankings sr
    JOIN 
        customer c ON sr.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        sr.rank_within_customer <= 5
),
Sales_Summary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS customer_name,
    ss.d_year,
    ss.total_web_sales,
    ss.total_orders,
    COALESCE(tc.total_sales, 0) AS total_customer_sales,
    CASE 
        WHEN ss.total_web_sales > 100000 THEN 'High Value Sales'
        WHEN ss.total_web_sales BETWEEN 50000 AND 100000 THEN 'Medium Value Sales'
        ELSE 'Low Value Sales'
    END AS sales_category
FROM 
    Top_Customers tc
FULL OUTER JOIN 
    Sales_Summary ss ON tc.c_customer_sk = ss.d_year
WHERE 
    ss.total_web_sales IS NOT NULL 
    OR tc.c_customer_sk IS NOT NULL
ORDER BY 
    ss.d_year ASC, total_customer_sales DESC;
