
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= (SELECT MIN(d.d_date)
                                FROM date_dim d
                                WHERE d.d_year = 2023)
        AND i.i_rec_end_date >= (SELECT MAX(d.d_date)
                                  FROM date_dim d
                                  WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS has_female_demo,
        MAX(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS has_male_demo
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
), 
aggregate_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS total_returns,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE profit_rank = 1)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_sk,
    i.i_item_id,
    rs.total_quantity,
    rs.total_net_profit,
    cr.total_return_quantity,
    cr.total_returns,
    cr.avg_return_amount,
    cc.demo_count,
    CASE 
        WHEN cc.has_female_demo = 1 AND cc.has_male_demo = 1 THEN 'Both'
        WHEN cc.has_female_demo = 1 THEN 'Female Only'
        WHEN cc.has_male_demo = 1 THEN 'Male Only'
        ELSE 'None' 
    END AS gender_demo_status
FROM 
    ranked_sales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    aggregate_returns cr ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN 
    customer_counts cc ON cc.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk 
                                                FROM web_sales ws 
                                                WHERE ws.ws_item_sk = i.i_item_sk)
WHERE 
    rs.total_net_profit > (SELECT AVG(total_net_profit) FROM ranked_sales) 
    AND (cr.total_return_quantity IS NULL OR cr.total_return_quantity < 50)
ORDER BY 
    rs.total_net_profit DESC, 
    rs.total_quantity ASC;
