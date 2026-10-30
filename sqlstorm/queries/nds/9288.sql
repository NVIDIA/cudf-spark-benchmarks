
WITH aggregate_sales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity_sold, 
        SUM(cs_net_paid) AS total_revenue,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2459487 AND 2459489
    GROUP BY cs_item_sk
), 
top_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        a.total_quantity_sold, 
        a.total_revenue, 
        a.total_orders,
        ROW_NUMBER() OVER (ORDER BY a.total_revenue DESC) AS rank
    FROM aggregate_sales a
    JOIN item i ON a.cs_item_sk = i.i_item_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), 
combined_data AS (
    SELECT 
        t.i_item_id AS id, 
        t.i_item_desc AS description, 
        t.total_quantity_sold,
        t.total_revenue, 
        t.total_orders,
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        c.total_web_orders
    FROM top_items t
    JOIN customer_details c ON t.total_orders > c.total_web_orders
)
SELECT 
    c_customer_id,
    c_first_name,
    c_last_name,
    SUM(total_revenue) AS overall_revenue,
    SUM(total_quantity_sold) AS overall_quantity_sold
FROM combined_data
GROUP BY c_customer_id, c_first_name, c_last_name
HAVING SUM(total_revenue) > 1000
ORDER BY overall_revenue DESC
LIMIT 10;
