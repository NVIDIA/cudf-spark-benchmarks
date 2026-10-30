
WITH  sales_cte AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_quantity,
        s.total_sales
    FROM 
        sales_cte s
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
    WHERE 
        s.rank <= 10
),
item_difference AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc,
        DENSE_RANK() OVER (ORDER BY i.i_current_price) AS price_rank 
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(id.price_rank, 0) AS price_rank,
    CASE 
        WHEN ts.total_sales > 10000 THEN 'High Sales'
        WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    top_sales ts
LEFT JOIN 
    item_difference id ON ts.i_item_id = id.i_item_id
ORDER BY 
    ts.total_sales DESC, ts.total_quantity DESC;
