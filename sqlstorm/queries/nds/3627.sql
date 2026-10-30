
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
),
SalesByMonth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month,
        SUM(ws.ws_ext_sales_price) AS monthly_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date), EXTRACT(MONTH FROM d.d_date)
)
SELECT
    s.sales_year,
    s.sales_month,
    COALESCE(SUM(tc.total_sales), 0) AS top_customers_sales,
    COALESCE(SUM(s.monthly_sales), 0) AS total_monthly_sales,
    AVG(tc.total_sales) AS avg_top_customer_sales
FROM 
    SalesByMonth s
LEFT JOIN 
    TopCustomers tc ON s.sales_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
      AND s.sales_month = EXTRACT(MONTH FROM DATE '2002-10-01') 
FULL OUTER JOIN date_dim d ON s.sales_year = EXTRACT(YEAR FROM d.d_date) 
      AND s.sales_month = EXTRACT(MONTH FROM d.d_date)
WHERE 
    d.d_current_month = 'Y'
GROUP BY 
    s.sales_year, s.sales_month
ORDER BY 
    s.sales_year DESC, s.sales_month DESC;
