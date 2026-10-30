
WITH  CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS recent_purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, d.d_date
),
IncomeBands AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        (cd.cd_dep_count + COALESCE(cd.cd_dep_employed_count, 0) + COALESCE(cd.cd_dep_college_count, 0)) AS total_dependencies
    FROM 
        customer_demographics cd
),
AggregatedData AS (
    SELECT 
        cte.c_customer_sk,
        cte.c_customer_id,
        cte.c_first_name,
        cte.c_last_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_gender,
        cd.cd_marital_status,
        cte.total_profit,
        cte.recent_purchase_rank
    FROM 
        CustomerCTE cte
    JOIN 
        IncomeBands ib ON cte.c_customer_sk = ib.hd_demo_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = cte.c_customer_sk
)
SELECT 
    a.c_customer_id,
    a.c_first_name,
    a.c_last_name,
    CASE 
        WHEN a.total_profit > 1000 THEN 'High Value Customer'
        WHEN a.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.cd_gender,
    a.cd_marital_status,
    CASE 
        WHEN a.recent_purchase_rank = 1 THEN 'Recent'
        WHEN a.recent_purchase_rank <= 3 THEN 'Active'
        ELSE 'Dormant'
    END AS purchase_status
FROM 
    AggregatedData a
WHERE 
    (a.cd_gender = 'F' AND a.total_profit > 500) OR 
    (a.cd_gender = 'M' AND a.total_profit > 700) OR 
    (a.cd_gender IS NULL AND a.total_profit IS NOT NULL)
ORDER BY 
    a.total_profit DESC
LIMIT 100;
