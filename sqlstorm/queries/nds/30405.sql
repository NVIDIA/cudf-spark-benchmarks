
WITH  sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year
), 
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
inventory_info AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    ii.total_inventory
FROM 
    sales_summary ss
LEFT JOIN 
    customer_data cd ON ss.sales_rank = cd.customer_rank
JOIN 
    inventory_info ii ON cd.c_current_cdemo_sk = ii.i_item_sk
WHERE 
    ss.total_sales > (
        SELECT AVG(total_sales) FROM sales_summary
    )
ORDER BY 
    ss.total_sales DESC, 
    cd.cd_purchase_estimate ASC
LIMIT 10;

