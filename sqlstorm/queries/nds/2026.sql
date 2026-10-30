
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spend,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
IncomeDistribution AS (
    SELECT 
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS num_customers
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_lower_bound, ib.ib_upper_bound
),
TopStores AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id, s.s_store_name
    ORDER BY 
        total_profit DESC
    LIMIT 5
),
CteWithRank AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spend,
        RANK() OVER (ORDER BY cs.total_spend DESC) AS spend_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    cwr.c_customer_id,
    cwr.c_first_name,
    cwr.c_last_name,
    cwr.total_spend,
    id.num_customers,
    ts.s_store_name
FROM 
    CteWithRank cwr
JOIN 
    IncomeDistribution id ON cwr.total_spend BETWEEN id.ib_lower_bound AND id.ib_upper_bound
LEFT JOIN 
    TopStores ts ON ts.total_profit > 0
WHERE 
    cwr.spend_rank <= 10
ORDER BY 
    cwr.total_spend DESC;
