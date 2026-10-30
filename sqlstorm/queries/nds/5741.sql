
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        dd.d_moy BETWEEN 1 AND 3
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY t.total_sales DESC) AS Rank,
    t.i_item_id AS Item_ID,
    t.i_item_desc AS Item_Description,
    t.total_quantity AS Total_Quantity_Sold,
    t.total_sales AS Total_Sales_Amount
FROM 
    TopItems t
ORDER BY 
    t.total_sales DESC;
