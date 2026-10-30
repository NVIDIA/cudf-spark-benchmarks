WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
        AND ws.ws_net_profit IS NOT NULL
), cumulative_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        sr_customer_sk
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), product_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
), final_result AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        pr.i_item_sk,
        pr.i_item_desc,
        pr.total_sold,
        pr.avg_price,
        CASE 
            WHEN cr.return_count IS NULL THEN 0
            ELSE cr.total_returned * pr.avg_price
        END AS return_value,
        rs.ws_net_profit
    FROM 
        customer_info ci 
    LEFT JOIN 
        cumulative_returns cr ON ci.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        ranked_sales rs ON ci.c_customer_sk = rs.ws_order_number
    LEFT JOIN 
        product_performance pr ON rs.ws_item_sk = pr.i_item_sk
    WHERE 
        ci.purchase_rank <= 100
        AND (cr.total_returned IS NULL OR cr.total_returned < 5)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(fr.ws_net_profit) AS total_net_profit,
    AVG(fr.return_value) AS avg_return_value,
    COUNT(DISTINCT fr.i_item_sk) AS unique_items,
    c.cd_gender
FROM 
    final_result fr
JOIN 
    customer_info c ON fr.c_customer_sk = c.c_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name, c.cd_gender
ORDER BY 
    total_net_profit DESC
LIMIT 10;