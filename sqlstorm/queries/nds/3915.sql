
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE c.c_birth_year < 1970
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(CASE WHEN cs.cs_item_sk IS NOT NULL THEN 1 END) AS sales_count,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM income_band AS ib
    LEFT JOIN customer AS c ON c.c_current_hdemo_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales AS cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ib.ib_income_band_sk
),
SalesYear AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales AS ws
    JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
ReturningCustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cs.total_returns,
        cs.total_return_amount,
        ibs.sales_count,
        ibs.total_profit,
        ibs.avg_purchase_estimate
    FROM CustomerStats AS cs
    JOIN IncomeBandStats AS ibs ON cs.cd_purchase_estimate BETWEEN ibs.avg_purchase_estimate - 500 AND ibs.avg_purchase_estimate + 500
    JOIN customer AS c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_returns > 0
)
SELECT 
    rcs.full_name,
    rcs.total_returns,
    rcs.total_return_amount,
    COALESCE(sy.total_sales, 0) AS total_sales_this_year,
    rcs.sales_count,
    rcs.total_profit,
    CASE 
        WHEN rcs.total_profit IS NULL THEN 'No Profit'
        WHEN rcs.total_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM ReturningCustomerStats AS rcs
LEFT JOIN SalesYear AS sy ON sy.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
ORDER BY rcs.total_return_amount DESC
LIMIT 100;
