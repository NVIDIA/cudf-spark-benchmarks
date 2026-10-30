
WITH  CustomerPurchaseCTE AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
IncomeBandCTE AS (
    SELECT 
        nd.hd_demo_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY nd.hd_demo_sk ORDER BY ib.ib_lower_bound) AS rn
    FROM 
        household_demographics nd
    JOIN 
        income_band ib ON nd.hd_income_band_sk = ib.ib_income_band_sk
),
RecentReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_amount) AS total_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        COALESCE(cp.total_spent, 0) AS total_spent,
        COALESCE(rr.total_returned, 0) AS total_returned,
        CASE 
            WHEN COALESCE(cp.total_spent, 0) > 1000 THEN 'High'
            WHEN COALESCE(cp.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS spending_category
    FROM 
        customer c
    LEFT JOIN 
        CustomerPurchaseCTE cp ON c.c_customer_sk = cp.c_customer_sk
    LEFT JOIN 
        RecentReturns rr ON c.c_customer_sk = rr.cr_returning_customer_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    SUM(ss.ss_net_profit) AS total_store_profit,
    AVG(total_spent) AS average_spent,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    (SELECT COUNT(*) FROM IncomeBandCTE WHERE ib_lower_bound <= 500) AS low_income_count,
    (SELECT COUNT(*) FROM IncomeBandCTE WHERE ib_upper_bound >= 1000) AS high_income_count
FROM 
    store s
JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN 
    SalesSummary ss_summary ON ss.ss_customer_sk = ss_summary.c_customer_sk
GROUP BY 
    s.s_store_sk, s.s_store_name
ORDER BY 
    total_store_profit DESC, average_spent DESC
LIMIT 10;
