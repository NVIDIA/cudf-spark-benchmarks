WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity_sold,
        ri.total_sales,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        ROW_NUMBER() OVER (ORDER BY ri.total_sales DESC) AS item_rank
    FROM 
        ranked_sales ri
    LEFT JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.rank_sales = 1
)
SELECT 
    ti.item_rank,
    ti.item_description,
    ti.total_quantity_sold,
    ti.total_sales,
    CASE 
        WHEN ti.total_sales > 1000 THEN 'High Sales'
        WHEN ti.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    top_items ti
WHERE 
    ti.total_quantity_sold > 10
ORDER BY 
    ti.total_sales DESC
LIMIT 10;