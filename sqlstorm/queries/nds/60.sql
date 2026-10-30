
WITH ranked_sales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY 
        ss_store_sk, ss_item_sk
),
best_selling_items AS (
    SELECT 
        r.ss_store_sk,
        i.i_item_id,
        r.total_quantity,
        r.total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.ss_store_sk ORDER BY r.total_sales DESC) AS item_rank
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ss_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    s.s_store_name,
    b.i_item_id,
    b.total_quantity,
    b.total_sales
FROM 
    best_selling_items b
JOIN 
    store s ON b.ss_store_sk = s.s_store_sk
ORDER BY 
    s.s_store_name, b.total_sales DESC;
