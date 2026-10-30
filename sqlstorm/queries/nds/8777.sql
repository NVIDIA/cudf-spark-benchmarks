
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN sr_item_sk IS NOT NULL THEN sr_ticket_number END) AS total_store_returns,
        COUNT(DISTINCT CASE WHEN cr_item_sk IS NOT NULL THEN cr_order_number END) AS total_catalog_returns,
        SUM(ws_net_profit) AS total_web_sales_profit,
        SUM(ss_net_profit) AS total_store_sales_profit
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
income_bracket AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound < 30000 THEN 'Low Income'
            WHEN ib.ib_lower_bound >= 30000 AND ib.ib_upper_bound < 70000 THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_category,
        hd.hd_buy_potential
    FROM 
        household_demographics hd
    INNER JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    ib.income_category,
    cs.total_store_returns,
    cs.total_catalog_returns,
    cs.total_web_sales_profit,
    cs.total_store_sales_profit
FROM 
    customer_summary cs
JOIN 
    income_bracket ib ON cs.c_customer_sk = ib.hd_demo_sk
ORDER BY 
    cs.total_web_sales_profit DESC,
    cs.total_store_returns DESC
LIMIT 100;
