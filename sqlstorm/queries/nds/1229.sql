
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
popular_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        i.i_item_id, i.i_product_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
),
sales_with_rank AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank,
        cs.total_purchases
    FROM 
        customer_summary cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    sr.c_customer_id,
    sr.total_spent,
    sr.spending_rank,
    pi.i_item_id,
    pi.i_product_name,
    pi.total_quantity_sold
FROM 
    sales_with_rank sr
LEFT JOIN 
    popular_items pi ON sr.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
WHERE 
    sr.total_purchases > 5
ORDER BY 
    sr.spending_rank, pi.total_quantity_sold DESC;
