
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL AND 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
),
out_of_stock_items AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) = 0
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    cte.total_quantity,
    cte.total_net_paid,
    COUNT(DISTINCT ooi.inv_item_sk) AS out_of_stock_count
FROM 
    customer_info ci
JOIN 
    sales_cte cte ON ci.c_customer_sk = cte.ws_item_sk
LEFT JOIN 
    out_of_stock_items ooi ON cte.ws_item_sk = ooi.inv_item_sk
WHERE 
    ci.cd_purchase_estimate > 500
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    cte.total_quantity, 
    cte.total_net_paid
HAVING 
    COUNT(DISTINCT ooi.inv_item_sk) > 0
ORDER BY 
    cte.total_net_paid DESC, 
    ci.c_last_name ASC
LIMIT 100;
