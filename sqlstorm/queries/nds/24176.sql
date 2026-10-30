
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_sales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        sales_summary
    WHERE 
        rank_sales <= 5
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(total_sales, 0) AS total_sales
    FROM 
        inventory inv
    LEFT JOIN 
        high_sales hs ON inv.inv_item_sk = hs.ws_item_sk
    WHERE 
        inv.inv_quantity_on_hand < (SELECT AVG(total_quantity) FROM high_sales)
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single' 
        END AS marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE 'Known'
        END AS income_band_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
final_report AS (
    SELECT 
        CASE WHEN inv.inv_item_sk IS NOT NULL THEN 'Under Inventory' ELSE 'Sufficient Inventory' END AS inventory_status,
        ca.c_customer_sk,
        ca.c_first_name,
        ca.c_last_name,
        ca.marital_status,
        ca.income_band_status,
        ih.total_sales
    FROM 
        customer_analysis ca
    LEFT JOIN 
        inventory_check inv ON ca.c_customer_sk = inv.inv_item_sk
    LEFT JOIN 
        high_sales ih ON inv.inv_item_sk = ih.ws_item_sk
)
SELECT 
    fr.inventory_status,
    COUNT(DISTINCT fr.c_customer_sk) AS customer_count,
    AVG(fr.total_sales) AS average_sales
FROM 
    final_report fr
GROUP BY 
    fr.inventory_status
HAVING 
    COUNT(DISTINCT fr.c_customer_sk) > 5
ORDER BY 
    average_sales DESC, 
    customer_count ASC;
