
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.total_quantity, 
        cs.total_sales, 
        cs.total_tax,
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        CustomerSales cs
), 
DateRangeSales AS (
    SELECT 
        dd.d_year, 
        SUM(ws.ws_ext_sales_price) AS yearly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020 AND dd.d_year <= 2023
    GROUP BY 
        dd.d_year
),
FinalSalesReport AS (
    SELECT 
        t.years, 
        COALESCE(y.yearly_sales, 0) AS total_sales
    FROM 
        (SELECT DISTINCT d_year AS years FROM date_dim) t
    LEFT JOIN 
        DateRangeSales y ON t.years = y.d_year
)
SELECT 
    tc.c_customer_sk, 
    tc.total_quantity, 
    tc.total_sales, 
    tc.total_tax, 
    fr.total_sales AS total_sales_2020_2023
FROM 
    TopCustomers tc
JOIN 
    FinalSalesReport fr ON tc.total_sales > 10000
WHERE 
    tc.sales_rank <= 100
ORDER BY 
    tc.total_sales DESC;
