WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
customer_segments AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        ce.c_first_name || ' ' || COALESCE(ce.c_last_name, '') AS full_name
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        customer ce ON ce.c_customer_sk = c.c_customer_sk
), 
annual_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS annual_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    cs.full_name,
    cs.gender,
    cs.income_band,
    rs.total_profit,
    COALESCE(ais.annual_profit, 0) AS annual_profit,
    CASE 
        WHEN rs.profit_rank = 1 THEN 'Top Customer'
        WHEN rs.total_profit <= 0 THEN 'No Profit'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    customer_segments cs
LEFT JOIN 
    ranked_sales rs ON cs.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    annual_sales ais ON ais.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
WHERE 
    (cs.income_band IS NULL OR cs.income_band NOT IN (SELECT ib_income_band_sk FROM income_band WHERE ib_income_band_sk < 2))
ORDER BY 
    cs.gender DESC NULLS LAST, 
    annual_profit DESC, 
    rs.total_profit ASC NULLS FIRST;