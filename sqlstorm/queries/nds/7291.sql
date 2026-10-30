
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_education_status IN ('BACHELORS', 'MASTERS')
),
sales_summary AS (
    SELECT 
        COUNT(*) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_profit) AS avg_profit,
        MIN(ws.ws_net_profit) AS min_profit,
        MAX(ws.ws_net_profit) AS max_profit
    FROM 
        ranked_sales ws
    WHERE 
        ws.rank <= 10
)
SELECT 
    s.total_sales,
    s.total_profit,
    s.avg_profit,
    s.min_profit,
    s.max_profit,
    d.d_year,
    d.d_month_seq
FROM 
    sales_summary s
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE 
    d.d_year = 2023
ORDER BY 
    s.total_profit DESC;
