
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        c.c_birth_year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023 
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq, d.d_quarter_seq, c.c_birth_year, cd.cd_gender, cd.cd_marital_status
)

SELECT 
    i.i_item_id,
    iss.total_quantity,
    iss.total_net_profit,
    COUNT(DISTINCT iss.d_year) AS years_active,
    COUNT(DISTINCT iss.d_month_seq) AS months_active,
    COUNT(DISTINCT iss.d_quarter_seq) AS quarters_active,
    MAX(iss.c_birth_year) AS youngest_customer_birth_year,
    MIN(iss.c_birth_year) AS oldest_customer_birth_year,
    SUM(CASE WHEN iss.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN iss.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN iss.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN iss.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
FROM 
    sales_summary AS iss
JOIN 
    item AS i ON iss.ws_item_sk = i.i_item_sk
GROUP BY 
    iss.ws_item_sk, i.i_item_id, iss.total_quantity, iss.total_net_profit
ORDER BY 
    iss.total_net_profit DESC
LIMIT 100;
