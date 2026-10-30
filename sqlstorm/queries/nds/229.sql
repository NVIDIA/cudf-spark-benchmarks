WITH MonthlySales AS (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), 
TopMonths AS (
    SELECT 
        year, 
        month,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        MonthlySales
)
SELECT 
    TM.year,
    TM.month,
    MS.total_sales,
    MS.total_orders,
    MS.unique_customers,
    CASE 
        WHEN TM.sales_rank <= 3 THEN 'Top Month' 
        ELSE 'Regular Month' 
    END AS month_category
FROM 
    TopMonths TM
JOIN 
    MonthlySales MS ON TM.year = MS.year AND TM.month = MS.month
LEFT JOIN 
    (SELECT 
         sr_store_sk,
         SUM(sr_return_amt_inc_tax) AS total_returns
     FROM 
         store_returns
     GROUP BY 
         sr_store_sk) SR ON SR.sr_store_sk = 1 
WHERE 
    MS.total_sales IS NOT NULL
ORDER BY 
    TM.year DESC, 
    TM.month DESC;