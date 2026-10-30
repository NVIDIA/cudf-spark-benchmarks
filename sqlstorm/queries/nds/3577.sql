
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit,
        i.i_item_desc,
        COALESCE(r.total_profit / NULLIF(r.total_quantity, 0), 0) AS avg_profit_per_unit,
        ROW_NUMBER() OVER (ORDER BY r.total_profit DESC) AS row_num
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.profit_rank <= 10
),
customer_preferences AS (
    SELECT 
        c.c_customer_id,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_credit_rating) AS min_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
purchase_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cp.c_customer_id,
    cs.total_spent,
    cs.order_count,
    ti.total_quantity AS item_quantity,
    ti.total_profit AS item_profit,
    ti.avg_profit_per_unit,
    cp.max_purchase_estimate,
    cp.min_credit_rating
FROM 
    customer_preferences cp
JOIN 
    purchase_summary cs ON cp.c_customer_id = cs.c_customer_id
JOIN 
    top_items ti ON ti.row_num <= 5
WHERE 
    cp.max_purchase_estimate > 1000 AND 
    cp.min_credit_rating IS NOT NULL
ORDER BY 
    cs.total_spent DESC;
