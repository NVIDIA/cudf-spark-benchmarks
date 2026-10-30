
WITH SalesData AS (
    SELECT 
        d.d_year,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, cs.cs_item_sk
),
RankedSales AS (
    SELECT 
        sd.d_year,
        sd.cs_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_amount,
        sd.avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales_amount DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    d.d_year,
    COUNT(*) AS top_selling_items,
    SUM(rs.total_quantity_sold) AS total_quantity_sold,
    SUM(rs.total_sales_amount) AS total_sales_amount
FROM 
    RankedSales rs
JOIN 
    date_dim d ON rs.d_year = d.d_year
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
