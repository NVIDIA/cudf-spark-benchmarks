
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_ext_sales_price DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 20100101 AND 20101231
),
TotalSales AS (
    SELECT 
        rs.cs_item_sk,
        SUM(rs.cs_ext_sales_price) AS total_sales,
        SUM(rs.cs_ext_discount_amt) AS total_discount
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 3
    GROUP BY 
        rs.cs_item_sk
),
SalesStats AS (
    SELECT 
        ts.cs_item_sk,
        ts.total_sales,
        ts.total_discount,
        COALESCE(ti.i_item_desc, 'Unknown') AS item_description,
        COALESCE(ti.i_brand, 'N/A') AS item_brand,
        COALESCE(tc.i_category, 'Uncategorized') AS category_name
    FROM 
        TotalSales ts
    LEFT JOIN 
        item ti ON ts.cs_item_sk = ti.i_item_sk
    LEFT JOIN 
        (SELECT 
            i_category_id, i_category
         FROM 
            (SELECT 
                i_category_id, 
                i_category, 
                RANK() OVER (ORDER BY i_category) AS category_rank
            FROM 
                item) a
         WHERE 
            category_rank <= 10) tc ON ti.i_category_id = tc.i_category_id
)
SELECT 
    ss.cs_item_sk,
    ss.item_description,
    ss.item_brand,
    ss.total_sales,
    ss.total_discount
FROM 
    SalesStats ss
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
