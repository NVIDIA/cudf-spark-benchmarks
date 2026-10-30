
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
),
SalesPerformance AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ss.ss_ticket_number) AS total_store_sales,
        SUM(ss.ss_net_paid) AS total_store_revenue,
        AVG(ss.ss_sales_price) AS avg_store_sales_price
    FROM 
        warehouse w
    LEFT JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id
),
IncomeBandSales AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
        SUM(cs.total_spent) AS total_spent_by_income_band
    FROM 
        income_band ib
    JOIN 
        CustomerSummary cs ON ib.ib_income_band_sk = cs.hd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    cs.total_web_orders,
    ib.ib_income_band_sk,
    ib.num_customers,
    ib.total_spent_by_income_band,
    sp.total_store_sales,
    sp.total_store_revenue,
    sp.avg_store_sales_price
FROM 
    CustomerSummary cs
JOIN 
    IncomeBandSales ib ON cs.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    SalesPerformance sp ON sp.total_store_sales IS NOT NULL
ORDER BY 
    cs.total_spent DESC, cs.c_last_name ASC, cs.c_first_name ASC;
