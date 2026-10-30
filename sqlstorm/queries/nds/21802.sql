
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS quantity_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked_sales.total_quantity,
        ROW_NUMBER() OVER (ORDER BY ranked_sales.total_quantity DESC) AS row_num
    FROM 
        item
    JOIN 
        ranked_sales ON item.i_item_sk = ranked_sales.ws_item_sk
    WHERE 
        ranked_sales.quantity_rank <= 5
),
store_revenue AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_revenue
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
    GROUP BY 
        ss_store_sk
),
null_address_sales AS (
    SELECT 
        COALESCE(NULLIF(c.c_first_name, ''), 'Unknown') AS customer_name,
        SUM(ss_net_paid) AS sales_amount
    FROM 
        store_sales ss
    LEFT JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_addr_sk IS NULL
    GROUP BY 
        COALESCE(NULLIF(c.c_first_name, ''), 'Unknown')
)
SELECT 
    h.i_item_id, 
    h.i_item_desc, 
    h.total_quantity, 
    s.total_revenue,
    n.customer_name,
    n.sales_amount
FROM 
    high_sales h
LEFT JOIN 
    store_revenue s ON s.ss_store_sk IN (1, 2, 3)  
FULL OUTER JOIN 
    null_address_sales n ON n.customer_name IS NOT NULL
WHERE 
    (h.total_quantity > 1000 OR s.total_revenue IS NULL)
ORDER BY 
    h.total_quantity DESC, 
    s.total_revenue ASC 
LIMIT 10;
