
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        MAX(ws_net_profit) AS max_net_profit,
        MIN(ws_net_profit) AS min_net_profit,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c_current_cdemo_sk AS demo_sk,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        COUNT(DISTINCT c_email_address) AS total_emails,
        AVG(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_ratio,
        AVG(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_ratio
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk
)
SELECT 
    d.d_date AS sale_date,
    SUM(ss.total_quantity_sold) AS total_quantity,
    SUM(ss.total_net_paid) AS total_sales,
    cs.total_customers,
    cs.total_emails,
    cs.male_ratio,
    cs.female_ratio,
    ss.max_net_profit,
    ss.min_net_profit,
    ss.avg_net_profit
FROM 
    sales_summary ss
JOIN 
    date_dim d ON d.d_date_sk = ss.ws_sold_date_sk
JOIN 
    customer_summary cs ON cs.demo_sk = ss.ws_item_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date, cs.total_customers, cs.total_emails, cs.male_ratio, cs.female_ratio, ss.max_net_profit, ss.min_net_profit, ss.avg_net_profit
ORDER BY 
    d.d_date;
