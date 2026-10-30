
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
Top_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        Customer_Sales cs
),
Date_Sales AS (
    SELECT 
        dd.d_year,
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year
),
Sales_Trend AS (
    SELECT 
        ds.d_year,
        ds.yearly_sales,
        LAG(ds.yearly_sales, 1) OVER (ORDER BY ds.d_year) AS prev_year_sales
    FROM 
        Date_Sales ds
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.order_count,
    tc.avg_order_value,
    st.d_year,
    st.yearly_sales,
    st.prev_year_sales,
    (st.yearly_sales - COALESCE(st.prev_year_sales, 0)) AS sales_change
FROM 
    Top_Customers tc
JOIN 
    Sales_Trend st ON tc.total_sales > 10000
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC, st.d_year;
