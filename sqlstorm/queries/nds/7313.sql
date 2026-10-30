
WITH SalesAnalysis AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
MonthlySales AS (
    SELECT 
        year,
        month,
        SUM(total_quantity_sold) AS monthly_quantity,
        SUM(total_sales) AS monthly_sales
    FROM (
        SELECT 
            d_year AS year,
            d_month_seq AS month,
            total_quantity_sold,
            total_sales
        FROM 
            SalesAnalysis
    ) AS SalesData
    GROUP BY 
        year, month
)
SELECT 
    ms.year,
    ms.month,
    ms.monthly_quantity,
    ms.monthly_sales,
    LAG(ms.monthly_sales) OVER (ORDER BY ms.year, ms.month) AS previous_month_sales,
    ms.monthly_sales - COALESCE(LAG(ms.monthly_sales) OVER (ORDER BY ms.year, ms.month), 0) AS sales_growth
FROM 
    MonthlySales ms
ORDER BY 
    ms.year, ms.month;
