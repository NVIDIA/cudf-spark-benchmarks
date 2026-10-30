
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_reason_sk,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rank_return
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'UNKNOWN' 
            WHEN hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= 50000 AND ib_upper_bound > 0) THEN 'LOW'
            WHEN hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 50000) THEN 'HIGH'
            ELSE 'UNKNOWN'
        END AS income_band
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
StoreSalesSubquery AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
FilteredReturns AS (
    SELECT 
        sr.*,
        c.income_band,
        si.total_net_profit,
        COALESCE(si.total_net_profit, 0) AS net_profit_or_zero
    FROM store_returns sr
    LEFT JOIN CustomerIncome c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN StoreSalesSubquery si ON sr.sr_item_sk = si.ss_item_sk
    WHERE sr_return_quantity > 0
)
SELECT 
    fr.sr_item_sk,
    fr.sr_return_quantity,
    fr.income_band,
    fr.net_profit_or_zero,
    CASE 
        WHEN fr.net_profit_or_zero > 1000 THEN 'HIGH PROFIT'
        WHEN fr.net_profit_or_zero BETWEEN 500 AND 1000 THEN 'MEDIUM PROFIT'
        ELSE 'LOW PROFIT'
    END AS profit_category,
    (SELECT COUNT(*) FROM RankedReturns rr WHERE rr.sr_item_sk = fr.sr_item_sk AND rr.rank_return = 1) AS top_return_rank_count
FROM FilteredReturns fr
WHERE fr.income_band <> 'UNKNOWN' 
    AND fr.net_profit_or_zero IS NOT NULL
ORDER BY fr.sr_item_sk, profit_category DESC
LIMIT 50;
