
WITH  sales_data AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM catalog_sales
    GROUP BY cs_item_sk
), 
ranked_sales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM sales_data sd
), 
high_sales AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_sales,
        rs.total_orders
    FROM ranked_sales rs
    WHERE rs.sales_rank <= 100
), 
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(NULLIF(i.i_color, ''), 'Unknown') AS item_color,
        COALESCE(NULLIF(i.i_brand, ''), 'Generic') AS item_brand
    FROM item i
)
SELECT 
    hi.i_item_sk,
    hi.i_item_desc,
    hi.item_color,
    hi.item_brand,
    hs.total_quantity,
    hs.total_sales,
    (SELECT 
        AVG(total_sales) 
     FROM high_sales) AS avg_sales,
    CASE 
        WHEN hs.total_sales IS NULL THEN 'No Sales'
        WHEN hs.total_sales > (SELECT 
                                   AVG(total_sales) 
                               FROM high_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM high_sales hs
FULL OUTER JOIN item_info hi ON hs.cs_item_sk = hi.i_item_sk
WHERE 
    (hi.item_color LIKE 'R%' OR hi.item_brand LIKE '%BrandA%')
    AND (hi.i_item_sk IS NOT NULL OR hs.cs_item_sk IS NOT NULL)
ORDER BY 
    hs.total_sales DESC NULLS LAST;
