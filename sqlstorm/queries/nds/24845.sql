
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 365 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
yearly_sales AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
item_inventory AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS quantity_on_hand
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.order_count,
    i.i_item_id,
    i.quantity_on_hand,
    ys.total_sales,
    (SELECT COUNT(*) FROM ranked_sales rs WHERE rs.sales_rank <= 5) AS top_ranked_sales_count,
    CASE 
        WHEN cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary) THEN 'Above Average'
        ELSE 'Below Average'
    END AS spending_category
FROM 
    customer_summary cs
JOIN 
    item_inventory i ON cs.order_count > 10
JOIN 
    yearly_sales ys ON ys.total_sales > 1000000
WHERE 
    cs.total_spent IS NOT NULL 
    AND i.quantity_on_hand IS NOT NULL
ORDER BY 
    cs.total_spent DESC, cs.order_count DESC
LIMIT 100;
