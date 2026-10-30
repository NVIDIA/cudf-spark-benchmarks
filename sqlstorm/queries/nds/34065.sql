
WITH  sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank,
        COALESCE(NULLIF(cd.cd_gender, ''), 'UNKNOWN') AS customer_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
sales_comparison AS (
    SELECT 
        sales1.ws_item_sk,
        sales1.total_net_profit AS last_period_profit,
        sales2.total_net_profit AS current_period_profit,
        (sales2.total_net_profit - sales1.total_net_profit) AS profit_change,
        CASE 
            WHEN sales1.total_net_profit = 0 THEN NULLIF(sales2.total_net_profit, 0) 
            ELSE ((sales2.total_net_profit - sales1.total_net_profit) / sales1.total_net_profit) * 100 
        END AS percent_growth
    FROM sales_data sales1
    JOIN sales_data sales2 ON sales1.ws_item_sk = sales2.ws_item_sk AND sales1.ws_sold_date_sk = sales2.ws_sold_date_sk - 30
    WHERE sales1.rank = 1
)
SELECT 
    s.ws_item_sk,
    s.last_period_profit,
    s.current_period_profit,
    COALESCE(s.profit_change, 0) AS profit_change,
    s.percent_growth,
    CASE 
        WHEN s.percent_growth > 0 THEN 'Increased'
        WHEN s.percent_growth < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS growth_trend,
    STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name) , ', ') AS associated_customers
FROM sales_comparison s
LEFT JOIN web_sales ws ON s.ws_item_sk = ws.ws_item_sk
LEFT JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
GROUP BY s.ws_item_sk, s.last_period_profit, s.current_period_profit, s.profit_change, s.percent_growth
ORDER BY s.percent_growth DESC;

