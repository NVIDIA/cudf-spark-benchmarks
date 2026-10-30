
WITH  item_sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price) > 1000
), 
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        COALESCE(cd_marital_status, 'Unknown') AS marital_status,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        c_birth_year BETWEEN 1980 AND 2000
), 
inventory_status AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
)
SELECT 
    ci.full_name, 
    ci.cd_gender, 
    ci.marital_status, 
    ci.cd_purchase_estimate,
    is_cte.ws_item_sk,
    is_cte.total_sales,
    is_cte.sales_count,
    COALESCE(inv.total_inventory, 0) AS inventory_count
FROM 
    customer_info ci
JOIN 
    item_sales_cte is_cte ON is_cte.ws_item_sk = ci.c_customer_sk
LEFT JOIN 
    inventory_status inv ON inv.inv_item_sk = is_cte.ws_item_sk
WHERE 
    is_cte.rn <= 10
ORDER BY 
    is_cte.total_sales DESC;
