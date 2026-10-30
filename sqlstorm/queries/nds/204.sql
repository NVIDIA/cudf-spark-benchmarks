
WITH sold_items AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sold, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= 2451545  
    GROUP BY 
        ws.ws_item_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
promotion_summary AS (
    SELECT 
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM 
        promotion p
    GROUP BY 
        p.p_item_sk
),
customers_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        'Web Sales' AS source,
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    UNION ALL
    SELECT 
        'Store Sales' AS source,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
final_summary AS (
    SELECT 
        si.ws_item_sk,
        COALESCE(si.total_sold, 0) AS total_sold,
        COALESCE(ii.total_inventory, 0) AS total_inventory,
        COALESCE(ps.promo_count, 0) AS promo_count,
        SUM(COALESCE(ss.total_revenue, 0)) AS total_revenue
    FROM 
        sold_items si
    FULL OUTER JOIN 
        inventory_info ii ON si.ws_item_sk = ii.inv_item_sk
    FULL OUTER JOIN 
        promotion_summary ps ON si.ws_item_sk = ps.p_item_sk
    LEFT JOIN 
        sales_summary ss ON si.ws_item_sk = ss.ws_item_sk
    GROUP BY 
        si.ws_item_sk, si.total_sold, ii.total_inventory, ps.promo_count
)
SELECT 
    item.i_item_id,
    fs.total_sold,
    fs.total_inventory,
    fs.promo_count,
    fs.total_revenue,
    CASE 
        WHEN fs.total_sold = 0 THEN NULL 
        ELSE (fs.total_revenue / fs.total_sold) 
    END AS avg_revenue_per_item
FROM 
    final_summary fs
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
WHERE 
    (fs.promo_count > 0 OR fs.total_inventory < 100)
ORDER BY 
    fs.total_revenue DESC
LIMIT 100;
