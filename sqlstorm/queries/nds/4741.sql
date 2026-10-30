
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
            WHEN SUM(ws.ws_net_profit) < 0 THEN 'Unprofitable'
            ELSE 'Neutral'
        END AS profitability_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_profit DESC) AS rank_within_band
    FROM 
        customer_info
)
SELECT 
    *,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    COALESCE(ca.ca_zip, '00000') AS zip
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE 
    (tc.rank_within_band <= 10 OR tc.profitability_status = 'Unprofitable')
    AND (tc.total_orders > 0 OR tc.profitability_status = 'Neutral')
ORDER BY 
    tc.hd_income_band_sk, tc.rank_within_band;
