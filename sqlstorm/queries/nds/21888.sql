
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price) > 0
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        MAX(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS is_married,
        COUNT(DISTINCT hd.hd_demo_sk) AS household_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY i.i_current_price DESC) AS price_rank
    FROM 
        item i
    WHERE 
        i.i_current_price IS NOT NULL
), 
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    LEFT JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
), 
ship_mode_count AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        ship_mode sm
    LEFT JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 0
), 
final_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        si.i_item_desc, 
        ss.total_sales,
        ws.total_inventory,
        smc.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS final_rank
    FROM 
        customer_info c
    INNER JOIN 
        sales_cte ss ON c.c_customer_sk = ss.ws_item_sk
    LEFT JOIN 
        item_details si ON ss.ws_item_sk = si.i_item_sk
    LEFT JOIN 
        warehouse_summary ws ON ws.w_warehouse_sk = ss.ws_item_sk
    LEFT JOIN 
        ship_mode_count smc ON smc.sm_ship_mode_id = 'FASTEST'
    WHERE 
        c.hd_income_band_sk IS NOT NULL 
        AND (CASE WHEN c.is_married = 1 THEN 'Married' ELSE 'Single' END) = 'Married'
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_sales,
    COALESCE(f.order_count, 0) AS order_count,
    CASE 
        WHEN f.order_count > 10 THEN 'Frequent Buyer' 
        WHEN f.order_count BETWEEN 5 AND 10 THEN 'Moderate Buyer' 
        ELSE 'Occasional Buyer' 
    END AS purchase_category
FROM 
    final_summary f
WHERE 
    f.final_rank <= 100
ORDER BY 
    f.total_sales DESC, 
    f.c_last_name ASC;
