
WITH  sales_data AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS rank_revenue
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
    HAVING 
        SUM(ss_net_paid) > 1000
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        sd.total_sold,
        sd.total_revenue
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ss_item_sk = i.i_item_sk
    WHERE 
        sd.rank_revenue <= 10
),
customer_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_id) AS unique_addresses
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
)
SELECT 
    ti.i_product_name,
    ti.total_sold,
    ti.total_revenue,
    cs.customer_count,
    cs.total_purchase_estimate,
    ai.unique_addresses
FROM 
    top_items ti
LEFT JOIN 
    customer_summary cs ON cs.cd_demo_sk = FLOOR(ti.total_sold % 10)  
LEFT JOIN 
    address_info ai ON ai.ca_state = 'NY'  
WHERE 
    ti.total_revenue > (SELECT AVG(sd.total_revenue) FROM sales_data sd)
ORDER BY 
    ti.total_revenue DESC
LIMIT 50;
