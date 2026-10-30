
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerPreferences AS (
    SELECT 
        c_customer_sk,
        MAX(cd_purchase_estimate) AS max_estimate,
        MAX(cd_credit_rating) AS max_credit_rating,
        COUNT(c_customer_sk) AS preference_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ri.ws_quantity) AS total_quantity,
        SUM(ri.ws_sales_price * ri.ws_quantity) AS total_sales
    FROM 
        RankedSales ri
    WHERE 
        ri.price_rank <= 3
    GROUP BY 
        ri.ws_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ci.total_sales,
    cp.max_estimate,
    cp.preference_count
FROM 
    CustomerPreferences cp
JOIN 
    TopItems ci ON cp.c_customer_sk = ci.ws_item_sk
JOIN 
    customer c ON c.c_customer_sk = cp.c_customer_sk
LEFT JOIN 
    inventory inv ON inv.inv_item_sk = ci.ws_item_sk AND inv.inv_quantity_on_hand > 0
WHERE 
    cp.max_estimate > 5000
ORDER BY 
    ci.total_sales DESC
LIMIT 10;
