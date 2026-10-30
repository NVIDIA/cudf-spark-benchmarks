
WITH  sales_data AS (
    SELECT 
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_paid DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        hd_income_band_sk 
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        hd_income_band_sk IS NOT NULL
),
sales_summary AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        sales_data sd
    JOIN 
        customer_info ci ON ci.hd_income_band_sk = 
            CASE 
                WHEN sd.ws_net_profit > 100 THEN 1 
                WHEN sd.ws_net_profit BETWEEN 50 AND 100 THEN 2 
                ELSE 3 
            END
    GROUP BY 
        ci.c_first_name, ci.c_last_name
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) as profit_rank
    FROM 
        sales_summary
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_quantity,
    s.total_net_paid,
    s.total_net_profit,
    CASE 
        WHEN s.profit_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    ranked_sales s
WHERE 
    s.total_net_paid > (SELECT AVG(total_net_paid) FROM ranked_sales) 
    OR s.total_quantity > (SELECT AVG(total_quantity) FROM ranked_sales)
ORDER BY 
    s.total_net_profit DESC
LIMIT 100;
