
WITH  customer_promotion AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
item_sales AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
top_promotion_items AS (
    SELECT 
        p.p_promo_id,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01')
      AND 
        p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01')
    GROUP BY 
        p.p_promo_id
    HAVING 
        SUM(ws.ws_quantity) > 1000
),
sales_summary AS (
    SELECT 
        cp.c_customer_id,
        COALESCE(SUM(tpi.total_quantity), 0) AS prom_items_sold,
        MAX(ip.average_profit) AS max_item_profit
    FROM 
        customer_promotion cp
    LEFT JOIN 
        top_promotion_items tpi ON cp.c_customer_id = tpi.p_promo_id
    LEFT JOIN 
        item_sales ip ON ip.order_count > 5
    GROUP BY 
        cp.c_customer_id
)
SELECT 
    ss.*, 
    CASE 
        WHEN ss.prom_items_sold > 500 THEN 'High Performer'
        WHEN ss.prom_items_sold BETWEEN 250 AND 500 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    sales_summary ss
ORDER BY 
    ss.prom_items_sold DESC, ss.max_item_profit DESC
LIMIT 100;
