
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk,
        ws_ship_mode_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk, 
        i.i_brand, 
        i.i_category, 
        MAX(ri.total_sales) AS max_sales
    FROM 
        ranked_sales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 5
    GROUP BY 
        ri.ws_item_sk, 
        i.i_brand, 
        i.i_category
),
address_counts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
demographics AS (
    SELECT 
        cd_gender, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
)
SELECT 
    ti.ws_item_sk, 
    ti.i_brand, 
    ti.i_category, 
    ac.ca_state, 
    ac.address_count, 
    dm.cd_gender, 
    dm.avg_purchase_estimate, 
    dm.total_dependencies
FROM 
    top_items ti
JOIN 
    address_counts ac ON ac.address_count > 100
JOIN 
    demographics dm ON dm.avg_purchase_estimate > 5000
ORDER BY 
    ti.max_sales DESC, 
    ac.address_count DESC;
