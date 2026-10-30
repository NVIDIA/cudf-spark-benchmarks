
WITH  customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ss_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws_quantity), 0) AS online_quantity,
        COUNT(DISTINCT ws_order_number) AS online_orders,
        COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
income_distribution AS (
    SELECT 
        COUNT(*) AS count,
        hd.hd_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown Income'
            ELSE CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_range
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
purchase_analysis AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_customer_id,
        cus.total_quantity,
        cus.online_quantity,
        cus.online_orders,
        cus.store_orders,
        id.income_range
    FROM 
        customer_summary cus
    JOIN 
        customer c ON cus.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_distribution id ON hd.hd_income_band_sk = id.hd_income_band_sk
)
SELECT 
    pa.c_customer_id,
    pa.total_quantity,
    pa.online_quantity,
    pa.online_orders,
    pa.store_orders,
    pa.income_range,
    RANK() OVER (PARTITION BY pa.income_range ORDER BY pa.total_quantity DESC) AS rank_within_income
FROM 
    purchase_analysis pa
WHERE 
    pa.total_quantity > 0 OR pa.online_quantity > 0
ORDER BY 
    pa.income_range, rank_within_income;
