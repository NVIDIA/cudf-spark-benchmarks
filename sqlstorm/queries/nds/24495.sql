
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS total_store_purchases,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS total_web_purchases,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_spent,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY COUNT(DISTINCT ss.ss_ticket_number) DESC) AS store_rank,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS web_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
IncomeRanges AS (
    SELECT 
        COUNT(*) AS customer_count,
        LAG(ib.ib_income_band_sk, 1, NULL) OVER (ORDER BY ib.ib_income_band_sk) AS lower_bound,
        ib.ib_income_band_sk AS upper_bound
    FROM 
        household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
ReturnStatistics AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_net_loss) AS net_loss 
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_store_purchases, 0) AS total_store_purchases,
    COALESCE(cs.total_web_purchases, 0) AS total_web_purchases,
    COALESCE(cs.total_store_spent, 0) AS total_store_spent,
    COALESCE(cs.total_web_spent, 0) AS total_web_spent,
    ir.customer_count,
    ir.lower_bound,
    ir.upper_bound,
    rs.total_returns,
    rs.return_count,
    rs.net_loss
FROM 
    CustomerStats cs
LEFT JOIN IncomeRanges ir ON cs.total_store_purchases BETWEEN ir.lower_bound AND ir.upper_bound
LEFT JOIN ReturnStatistics rs ON cs.c_customer_sk = rs.cr_item_sk
WHERE 
    (cs.store_rank = 1 OR cs.web_rank = 1)
    AND (cs.total_store_spent + cs.total_web_spent) > 1000
    AND (cs.total_store_spent IS NOT NULL OR cs.total_web_spent IS NOT NULL)
ORDER BY 
    cs.total_store_spent DESC, 
    cs.total_web_spent DESC
LIMIT 100;
