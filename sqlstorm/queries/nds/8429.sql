
WITH SalesData AS (
    SELECT 
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_ship_customer_sk) AS unique_customers,
        AVG(cs_sales_price) AS average_sales_price,
        CAST(d.d_date AS DATE) AS sales_date
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs_order_number, d.d_date
),
RankedSales AS (
    SELECT 
        sd.sales_date,
        sd.total_sales,
        sd.total_discount,
        sd.unique_customers,
        sd.average_sales_price,
        ROW_NUMBER() OVER (PARTITION BY sd.sales_date ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    r.sales_date,
    r.total_sales,
    r.total_discount,
    r.unique_customers,
    r.average_sales_price
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_date, r.total_sales DESC;
