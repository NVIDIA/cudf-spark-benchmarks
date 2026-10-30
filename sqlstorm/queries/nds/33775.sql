
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT max(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT 
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        ss.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_summary ss ON cs.cs_item_sk = ss.cs_item_sk
    WHERE 
        ss.level < 3
),
top_selling_items AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales cs
    INNER JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND
        COALESCE(i.i_brand, 'Unknown') <> 'Unknown'
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        SUM(cs.cs_quantity) > 100
),
returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
summary AS (
    SELECT 
        tsi.cs_item_sk,
        tsi.total_quantity,
        tsi.total_sales_price,
        tsi.avg_sales_price,
        COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (tsi.total_sales_price - COALESCE(r.total_returned_amount, 0)) AS net_sales
    FROM 
        top_selling_items tsi
    LEFT JOIN 
        returns r ON tsi.cs_item_sk = r.cr_item_sk
)
SELECT 
    s.cs_item_sk,
    s.total_quantity,
    s.total_sales_price,
    s.total_returned_quantity,
    s.total_returned_amount,
    s.net_sales,
    ROW_NUMBER() OVER (ORDER BY s.net_sales DESC) AS rank
FROM 
    summary s
ORDER BY 
    s.net_sales DESC
LIMIT 10;
