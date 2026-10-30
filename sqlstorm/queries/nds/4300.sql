
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(rs.ws_order_number) AS order_count,
        CASE 
            WHEN SUM(rs.ws_net_profit) > 500 THEN 'High'
            WHEN SUM(rs.ws_net_profit) BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.ws_order_number = ci.c_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_profit,
    ss.order_count,
    ss.profit_category,
    d.d_date AS return_date,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns
FROM 
    sales_summary ss
LEFT JOIN 
    catalog_returns cr ON ss.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
WHERE 
    ss.total_profit IS NOT NULL
    AND ss.profit_category = 'High'
GROUP BY 
    ss.c_customer_sk, ss.c_first_name, ss.c_last_name, ss.total_profit, ss.order_count, ss.profit_category, d.d_date
ORDER BY 
    total_profit DESC;
