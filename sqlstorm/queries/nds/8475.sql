
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        rs.total_sales
    FROM 
        customer c
    JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.sales_rank <= 10
), 
sales_by_month AS (
    SELECT 
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS sales_total
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq
), 
monthly_average AS (
    SELECT 
        AVG(sales_total) AS average_monthly_sales
    FROM 
        sales_by_month
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    mb.average_monthly_sales,
    CASE 
        WHEN tc.total_sales > mb.average_monthly_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    top_customers tc
CROSS JOIN 
    monthly_average mb
ORDER BY 
    tc.total_sales DESC;
