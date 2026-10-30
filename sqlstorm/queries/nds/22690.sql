WITH  sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price BETWEEN 10 AND 100
    GROUP BY 
        ws.ws_item_sk
),
customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS customer_total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.customer_total_profit,
        ROW_NUMBER() OVER (ORDER BY cr.customer_total_profit DESC) AS customer_rank
    FROM 
        customer_revenue cr
    WHERE 
        cr.customer_total_profit IS NOT NULL 
        AND cr.customer_total_profit > 0
),
monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    top.c_customer_sk,
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_net_profit,
    ms.monthly_net_profit,
    CASE 
        WHEN ms.monthly_net_profit IS NULL THEN 0
        ELSE ms.monthly_net_profit
    END AS monthly_profit_or_zero,
    CASE 
        WHEN top.customer_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    sales_data sd
JOIN 
    top_customers top ON sd.ws_item_sk = sd.ws_item_sk
LEFT JOIN 
    monthly_sales ms ON ms.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
                       AND ms.d_month_seq = EXTRACT(MONTH FROM cast('2002-10-01' as date))
WHERE 
    sd.total_quantity IS NOT NULL 
    AND sd.total_net_profit > 0
ORDER BY 
    sd.total_net_profit DESC, 
    monthly_profit_or_zero DESC;