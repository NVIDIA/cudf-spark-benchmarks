
WITH sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
return_summary AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returned_amount, 0)) AS net_sales,
        (COALESCE(ss.total_sales, 0) / NULLIF(COALESCE(ss.total_quantity, 0), 0)) AS unit_price,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) > 10000 THEN 'High'
            WHEN COALESCE(ss.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.cs_item_sk
    LEFT JOIN 
        return_summary rs ON i.i_item_sk = rs.cr_item_sk
),
ranked_items AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_category ORDER BY net_sales DESC) AS sales_rank
    FROM 
        item_details
)

SELECT 
    w.w_warehouse_id,
    i.i_item_id,
    i.i_product_name,
    i.total_quantity,
    i.total_sales,
    i.total_returned_quantity,
    i.total_returned_amount,
    i.net_sales,
    i.unit_price,
    i.sales_category,
    i.sales_rank
FROM 
    ranked_items i
JOIN 
    inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE 
    i.sales_rank <= 10
    AND (i.total_sales > 0 OR i.total_returned_amount > 0)
    AND w.w_country = 'USA'
ORDER BY 
    w.w_warehouse_id, i.sales_rank;
