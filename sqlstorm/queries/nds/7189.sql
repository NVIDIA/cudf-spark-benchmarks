
WITH RankedSales AS (
    SELECT 
        cs.cs_order_number,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
        DENSE_RANK() OVER (ORDER BY SUM(cs.cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023 AND 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        cs.cs_order_number
), 
TopSales AS (
    SELECT 
        sales_rank, 
        total_sales, 
        total_discount, 
        unique_customers
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.sales_rank,
    ts.total_sales,
    ts.total_discount,
    ts.unique_customers,
    ROUND(ts.total_sales / NULLIF(ts.unique_customers, 0), 2) AS avg_sales_per_customer
FROM 
    TopSales ts
ORDER BY 
    ts.sales_rank;
