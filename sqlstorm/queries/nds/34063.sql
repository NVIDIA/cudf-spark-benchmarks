WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
active_items AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price
    FROM 
        item
    WHERE 
        i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS lifetime_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
date_ranges AS (
    SELECT DISTINCT 
        d.d_date_sk,
        CASE 
            WHEN d.d_dow IN (1, 2, 3, 4, 5) THEN 'Weekday'
            ELSE 'Weekend'
        END AS day_type
    FROM 
        date_dim d
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ss.total_quantity, 0) AS web_sales_quantity,
    COALESCE(ss.total_profit, 0.00) AS web_sales_profit,
    ai.i_item_desc,
    ai.i_current_price,
    dr.day_type
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    active_items ai ON ss.ws_item_sk = ai.i_item_sk
LEFT JOIN 
    date_ranges dr ON ss.ws_sold_date_sk = dr.d_date_sk
WHERE 
    (ci.lifetime_value > 1000 AND ci.cd_gender = 'F') OR 
    (ci.lifetime_value <= 1000 AND ci.cd_marital_status = 'M') 
ORDER BY 
    ci.c_customer_sk, web_sales_profit DESC;