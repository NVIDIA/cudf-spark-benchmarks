WITH  sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
return_summary AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.total_web_profit,
    ci.total_web_orders,
    ss.total_net_profit AS store_net_profit,
    ss.total_sales AS number_of_sales,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    rs.total_returns
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ss.sales_rank = 1
LEFT JOIN 
    return_summary rs ON ci.c_customer_sk = rs.sr_item_sk  
WHERE 
    ci.total_web_profit > 1000
ORDER BY 
    ci.total_web_profit DESC, ci.c_last_name;