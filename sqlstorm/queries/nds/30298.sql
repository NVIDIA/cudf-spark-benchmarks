
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),

store_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS available_quantity
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),

customer_growth AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        cd.cd_gender
),

positive_growth AS (
    SELECT 
        cg.cd_gender,
        cg.customer_count,
        cg.avg_purchase_estimate,
        COALESCE(ss.total_quantity, 0) AS total_sales_quantity,
        COALESCE(ss.total_net_paid, 0) AS total_sales_amount
    FROM 
        customer_growth cg
    LEFT JOIN 
        sales_summary ss ON ss.ws_item_sk IN (SELECT i_item_sk FROM item)
    WHERE 
        cg.avg_purchase_estimate > (
            SELECT 
                AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_purchase_estimate IS NOT NULL
        )
)

SELECT 
    pg.cd_gender,
    pg.customer_count,
    pg.avg_purchase_estimate,
    pg.total_sales_quantity,
    pg.total_sales_amount,
    si.available_quantity,
    CASE 
        WHEN pg.customer_count > 100 THEN 'High Engagement'
        WHEN pg.customer_count BETWEEN 50 AND 100 THEN 'Medium Engagement'
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM 
    positive_growth pg
LEFT JOIN 
    store_inventory si ON si.inv_item_sk IN (SELECT ss.ws_item_sk FROM sales_summary ss)
ORDER BY 
    pg.total_sales_amount DESC;
