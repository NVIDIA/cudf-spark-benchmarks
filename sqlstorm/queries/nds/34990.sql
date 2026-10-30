
WITH  sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_profit) AS total_profit,
        COUNT(ss_ticket_number) AS total_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name

    UNION ALL

    SELECT 
        s_store_sk,
        CONCAT(s_store_name, ' - Processed'),
        SUM(ss_net_profit) * 0.9 AS total_profit, 
        COUNT(ss_ticket_number) + 5 AS total_sales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss_net_profit < 0
    GROUP BY 
        s_store_sk, s_store_name
), 
date_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2001
    GROUP BY 
        d.d_date
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
combined_sales AS (
    SELECT 
        sh.s_store_name,
        sh.total_profit,
        sh.total_sales,
        COALESCE(ds.total_web_profit, 0) AS total_web_profit,
        ci.c_first_name,
        ci.c_last_name,
        ci.gender,
        ci.buy_potential
    FROM 
        sales_hierarchy sh
    LEFT JOIN 
        date_sales ds ON ds.d_date = DATE '2002-10-01'
    JOIN 
        customer_info ci ON ci.c_customer_sk = sh.s_store_sk 
)
SELECT 
    c.s_store_name,
    c.total_profit,
    c.total_sales,
    c.total_web_profit,
    c.c_first_name,
    c.c_last_name,
    c.gender,
    c.buy_potential,
    CASE 
        WHEN c.total_profit > 10000 THEN 'High Profit'
        WHEN c.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    combined_sales c
WHERE 
    (c.total_sales > 5 OR c.total_web_profit > 500)
ORDER BY 
    c.total_profit DESC
LIMIT 50;
