
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.ws_sold_date_sk
),
item_ranked AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_dep_count AS VARCHAR(255))
        END AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ss.ss_net_profit) AS customer_profit
    FROM 
        customer_info ci
    JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    ORDER BY 
        customer_profit DESC
    LIMIT 10
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_tax, 0) AS total_tax,
    COALESCE(ir.total_profit, 0) AS item_profit,
    ir.item_rank
FROM 
    top_customers t
LEFT JOIN 
    sales_summary ss ON t.c_customer_sk = ss.total_quantity
LEFT JOIN 
    item_ranked ir ON ir.item_rank = 1
WHERE 
    (t.customer_profit >= 1000 OR (t.customer_profit < 1000 AND t.c_first_name LIKE 'A%'))
ORDER BY 
    t.c_customer_sk DESC;
