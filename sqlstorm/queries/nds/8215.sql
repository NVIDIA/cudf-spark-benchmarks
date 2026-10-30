
WITH RankedSales AS (
    SELECT 
        cs.cs_sold_date_sk, 
        cs.cs_item_sk, 
        cs.cs_sales_price, 
        cs.cs_quantity, 
        SUM(cs.cs_sales_price * cs.cs_quantity) OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
),
TopSellingItems AS (
    SELECT 
        rs.cs_item_sk, 
        SUM(rs.cs_quantity) AS total_quantity_sold,
        AVG(rs.cs_sales_price) AS average_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.cs_item_sk
)
SELECT 
    tsi.cs_item_sk, 
    ti.i_item_desc, 
    tsi.total_quantity_sold, 
    tsi.average_sales_price
FROM 
    TopSellingItems tsi
JOIN 
    item ti ON tsi.cs_item_sk = ti.i_item_sk
ORDER BY 
    tsi.total_quantity_sold DESC;
