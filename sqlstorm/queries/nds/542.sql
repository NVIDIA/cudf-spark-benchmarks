
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(hd.hd_demo_sk) AS count_customers,
        AVG(hd.hd_vehicle_count) AS avg_vehicles
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Purchases'
        WHEN cs.total_spent < 1000 THEN 'Low Spender'
        WHEN cs.total_spent BETWEEN 1000 AND 5000 THEN 'Moderate Spender'
        ELSE 'High Spender'
    END AS spending_category,
    ir.count_customers,
    ir.avg_vehicles,
    rs.ws_sales_price,
    rs.sales_rank
FROM 
    CustomerStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    IncomeRanges ir ON cs.order_count > 0
JOIN 
    RankedSales rs ON cs.order_count > 2 AND rs.sales_rank = 1
WHERE 
    c.c_birth_year <= 1990
ORDER BY 
    cs.total_spent DESC,
    ir.count_customers DESC;
