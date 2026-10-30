
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        SUM(ws_net_paid) OVER (PARTITION BY ws_item_sk) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
max_sales AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.total_net_paid) AS max_net_paid
    FROM 
        ranked_sales rs
    GROUP BY 
        rs.ws_item_sk
),
filtered_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(MAX(ms.max_net_paid), 0) AS highest_sales
    FROM 
        item i
    LEFT JOIN 
        max_sales ms ON i.i_item_sk = ms.ws_item_sk
    WHERE 
        LENGTH(i.i_item_desc) > 30
    GROUP BY 
        i.i_item_sk, 
        i.i_item_desc
    HAVING 
        COALESCE(MAX(ms.max_net_paid), 0) > 0
),
sales_summary AS (
    SELECT 
        f.i_item_desc,
        f.highest_sales,
        COUNT(f.i_item_sk) AS item_count
    FROM 
        filtered_items f
    JOIN 
        store_sales ss ON ss.ss_item_sk = f.i_item_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        f.i_item_desc, 
        f.highest_sales
)
SELECT 
    s.i_item_desc,
    s.highest_sales,
    s.item_count,
    CASE 
        WHEN s.highest_sales = 0 THEN 'No Sales'
        WHEN s.item_count = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS stock_status,
    CONCAT('Item: ', s.i_item_desc, ' | Sales: ', s.highest_sales) AS sales_report
FROM 
    sales_summary s
WHERE 
    s.highest_sales > (SELECT AVG(highest_sales) FROM filtered_items)
ORDER BY 
    s.highest_sales DESC
LIMIT 10;
