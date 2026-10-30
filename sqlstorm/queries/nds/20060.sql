
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        COUNT(DISTINCT w.ws_item_sk) AS items_bought
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN
        web_sales w ON w.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, hd.hd_income_band_sk
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders 
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 10.00 OR (i.i_current_price IS NULL AND i.i_color IS NOT NULL)
    GROUP BY 
        i.i_item_id, i.i_current_price, i.i_brand, i.i_category
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    rs.total_quantity,
    rs.avg_sales_price,
    id.total_orders,
    CASE 
        WHEN id.total_orders > 5 THEN 'Frequent Buyer'
        WHEN id.total_orders BETWEEN 1 AND 5 THEN 'Occasional Buyer'
        ELSE 'New Buyer'
    END AS buyer_category
FROM 
    customer_details cd
LEFT JOIN 
    ranked_sales rs ON cd.income_band_sk = rs.ws_item_sk
LEFT JOIN 
    item_details id ON cd.items_bought = id.total_orders
WHERE 
    (cd.items_bought IS NULL OR cd.items_bought > 0)
AND 
    (rs.total_quantity IS NOT NULL OR cd.cd_purchase_estimate < 1000)
ORDER BY 
    cd.c_customer_id, 
    CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END DESC,
    rs.avg_sales_price DESC,
    id.total_orders DESC;
