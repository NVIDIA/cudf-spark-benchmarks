
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk, ws_sold_date_sk
),
high_value_customers AS (
    SELECT 
        c_customer_id,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        ROW_NUMBER() OVER (ORDER BY cd_purchase_estimate DESC) AS value_rank
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
inventory_levels AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    hs.total_sales,
    iv.total_inventory,
    CASE 
        WHEN hv.value_rank <= 10 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM 
    ranked_sales AS hs
JOIN 
    customer AS c ON c.c_customer_sk = hs.ws_bill_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    high_value_customers AS hv ON c.c_customer_id = hv.c_customer_id
LEFT JOIN 
    inventory_levels AS iv ON hs.ws_item_sk = iv.inv_item_sk
WHERE 
    hs.sales_rank = 1
    AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
ORDER BY 
    hs.total_sales DESC
LIMIT 100;

