WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_product_name
),
sales_comparison AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        its.i_item_id,
        its.i_product_name,
        its.total_quantity_sold,
        its.average_sales_price,
        CASE 
            WHEN its.total_quantity_sold > 100 THEN 'High Volume'
            WHEN its.total_quantity_sold BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS sales_volume_category
    FROM customer_info ci
    JOIN item_summary its ON ci.c_customer_id = its.i_item_id  
    WHERE ci.ca_state IN ('CA', 'NY')  
)
SELECT
    COUNT(DISTINCT c_customer_id) AS total_customers,
    sales_volume_category,
    AVG(average_sales_price) AS avg_price,
    SUM(total_quantity_sold) AS total_units_sold
FROM sales_comparison
GROUP BY sales_volume_category
ORDER BY total_customers DESC;