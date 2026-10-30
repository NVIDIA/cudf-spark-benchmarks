
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rank_return
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerIncomeSummary AS (
    SELECT 
        c.c_customer_sk,
        hd.hd_income_band_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, hd.hd_income_band_sk
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        COUNT(ws_order_number) AS web_sales_count,
        AVG(ws_net_profit) AS average_web_profit,
        COUNT(DISTINCT ws_order_number) FILTER (WHERE ws_net_profit IS NOT NULL) AS non_null_web_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.hd_income_band_sk,
    ir.total_returned,
    ir.total_return_amt,
    it.web_sales_count,
    it.average_web_profit,
    it.non_null_web_sales
FROM 
    CustomerIncomeSummary ci
LEFT JOIN 
    RankedReturns ir ON ci.c_customer_sk = ir.sr_item_sk
LEFT JOIN 
    ItemSummary it ON ir.sr_item_sk = it.i_item_sk
WHERE 
    (ci.hd_income_band_sk IS NOT NULL OR ci.return_days > 5) 
    AND (ir.total_returned > 0 OR it.web_sales_count IS NULL)
ORDER BY 
    ci.c_customer_sk, it.average_web_profit DESC NULLS LAST;
