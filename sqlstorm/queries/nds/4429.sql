
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
),
top_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_net_profit
    FROM 
        ranked_sales r
    WHERE 
        r.profit_rank = 1
    OR (r.profit_rank > 1 AND r.profit_rank <= 5)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_week_seq IN (
            SELECT 
                d_week_seq 
            FROM 
                date_dim 
            WHERE 
                d_date BETWEEN '2022-01-01' AND '2022-12-31'
        )
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.total_spent,
    i.i_item_id,
    i.i_item_desc,
    i.i_current_price,
    COALESCE(ts.ws_quantity, 0) AS sold_quantity
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.total_spent > 1000
LEFT JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    ci.total_spent IS NOT NULL
ORDER BY 
    ci.total_spent DESC, 
    ci.c_last_name, 
    ci.c_first_name
LIMIT 100;
