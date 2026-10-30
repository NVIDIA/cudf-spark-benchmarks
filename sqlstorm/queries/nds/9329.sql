
WITH ranked_sales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked_sales.total_quantity,
        ranked_sales.total_sales
    FROM 
        ranked_sales
    JOIN 
        item ON ranked_sales.cs_item_sk = item.i_item_sk
    WHERE 
        ranked_sales.sales_rank <= 10
),
customer_sales AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        SUM(web_sales.ws_net_paid) AS total_spent
    FROM 
        web_sales
    JOIN 
        customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    GROUP BY 
        customer.c_customer_id, customer.c_first_name, customer.c_last_name
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    ti.i_item_id,
    ti.i_item_desc,
    cs.total_spent
FROM 
    customer_sales cs
JOIN 
    top_items ti ON cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC, ti.total_sales DESC
LIMIT 50;
