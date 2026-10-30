
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_preferred_cust_flag,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer 
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
    LEFT JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
),
inventory_info AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
promotions AS (
    SELECT 
        p_item_sk,
        COUNT(*) AS promo_count
    FROM 
        promotion
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        p_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_preferred_cust_flag,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    r.total_sales,
    COALESCE(ii.total_inventory, 0) AS total_inventory,
    COALESCE(p.promo_count, 0) AS promo_count,
    CASE 
        WHEN ci.cd_gender = 'M' THEN 'Male Group'
        WHEN ci.cd_gender = 'F' THEN 'Female Group'
        ELSE 'Other'
    END AS gender_group,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS sales_status
FROM 
    customer_info ci
JOIN 
    ranked_sales r ON ci.c_customer_sk = r.ws_item_sk 
LEFT JOIN 
    inventory_info ii ON r.ws_item_sk = ii.inv_item_sk 
LEFT JOIN 
    promotions p ON r.ws_item_sk = p.p_item_sk 
WHERE 
    (ci.c_preferred_cust_flag = 'Y' OR ci.cd_purchase_estimate > 10000)
    AND r.total_sales > 50000
    AND (ci.cd_gender IS NOT NULL OR ci.cd_marital_status IS NULL)
ORDER BY 
    total_sales DESC,
    ci.c_customer_sk ASC
LIMIT 100;
