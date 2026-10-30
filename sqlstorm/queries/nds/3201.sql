
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ca.ca_state IS NOT NULL 
        AND cd.cd_marital_status = 'M' 
        AND hd.hd_buy_potential IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, hd.hd_income_band_sk
),
profit_summary AS (
    SELECT 
        income_band,
        COUNT(*) AS customer_count,
        SUM(total_profit) AS total_profit,
        AVG(total_profit) AS avg_profit
    FROM 
        customer_info
    GROUP BY 
        income_band
),
ranked_profits AS (
    SELECT 
        income_band,
        customer_count,
        total_profit,
        avg_profit,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        profit_summary
)
SELECT 
    rp.income_band,
    rp.customer_count,
    rp.total_profit,
    rp.avg_profit,
    CASE 
        WHEN rp.profit_rank <= 5 THEN 'Top 5 Income Bands'
        ELSE 'Other Income Bands'
    END AS income_band_category
FROM 
    ranked_profits rp
WHERE 
    rp.total_profit > 0
ORDER BY 
    rp.total_profit DESC;
