
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
), top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity_sold,
        r.total_sales_amount
    FROM 
        item i
    JOIN 
        ranked_sales r ON i.i_item_sk = r.ws_item_sk
    WHERE 
        r.sales_rank <= 10
), customer_purchases AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_quantity) AS total_items_purchased,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), customer_details AS (
    SELECT 
        cp.c_customer_id,
        cp.total_items_purchased,
        cp.total_spent,
        ROW_NUMBER() OVER (ORDER BY cp.total_spent DESC) AS purchase_rank
    FROM 
        customer_purchases cp
), final_report AS (
    SELECT 
        ci.c_customer_id,
        ci.total_items_purchased,
        ci.total_spent,
        ti.i_item_id,
        ti.i_item_desc
    FROM 
        customer_details ci
    LEFT JOIN 
        top_items ti ON ci.total_items_purchased > 0
    WHERE 
        ci.purchase_rank <= 10
)
SELECT 
    fr.c_customer_id,
    fr.total_items_purchased,
    fr.total_spent,
    ARRAY_AGG(DISTINCT fr.i_item_id) AS purchased_item_ids,
    ARRAY_AGG(DISTINCT fr.i_item_desc) AS purchased_item_descriptions
FROM 
    final_report fr
GROUP BY 
    fr.c_customer_id, fr.total_items_purchased, fr.total_spent
ORDER BY 
    fr.total_spent DESC;
