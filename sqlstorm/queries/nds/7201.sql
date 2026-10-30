
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Sales_Rank AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Top_Customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sr.total_sales,
        sr.order_count
    FROM 
        Sales_Rank sr
    JOIN 
        customer c ON sr.c_customer_sk = c.c_customer_sk
    WHERE 
        sr.sales_rank <= 10
),
Sales_Statistics AS (
    SELECT 
        MAX(total_sales) AS max_sales,
        MIN(total_sales) AS min_sales,
        AVG(total_sales) AS avg_sales
    FROM 
        Customer_Sales
),
Final_Output AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.order_count,
        ss.max_sales,
        ss.min_sales,
        ss.avg_sales
    FROM 
        Top_Customers tc, Sales_Statistics ss
)

SELECT 
    *
FROM 
    Final_Output
ORDER BY 
    total_sales DESC;
