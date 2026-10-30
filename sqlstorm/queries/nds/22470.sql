
WITH RankedReturns AS (
    SELECT 
        sr_store_sk,
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_store_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_store_sk, sr_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown'
            WHEN cd.cd_dep_count > 5 THEN 'Large Family'
            ELSE 'Small Family'
        END AS family_size_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
WebSalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS num_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        SUM(ws_quantity) AS total_items_ordered
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
JoinResults AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(wsd.num_orders, 0) AS num_orders,
        wsd.total_spent,
        COALESCE(rr.total_returns, 0) AS total_returns,
        rr.total_returned_quantity,
        rr.total_return_amt,
        cd.family_size_category,
        cd.income_band
    FROM CustomerDetails cd
    LEFT JOIN WebSalesDetails wsd ON cd.c_customer_sk = wsd.ws_bill_customer_sk
    LEFT JOIN RankedReturns rr ON cd.c_customer_sk = rr.sr_customer_sk
)
SELECT 
    j.c_first_name,
    j.c_last_name,
    j.num_orders,
    j.total_spent,
    j.total_returns,
    j.total_returned_quantity,
    j.total_return_amt,
    j.family_size_category,
    j.income_band,
    CASE 
        WHEN j.num_orders > 5 AND j.total_spent > 1000 THEN 'Loyal Customer'
        WHEN j.num_orders < 1 THEN 'New Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM JoinResults j
WHERE j.total_return_amt IS NOT NULL 
AND j.total_return_amt > (
    SELECT AVG(total_return_amt) 
    FROM RankedReturns 
    WHERE sr_store_sk = (SELECT MIN(sr_store_sk) FROM RankedReturns)
)
ORDER BY j.total_spent DESC, j.c_last_name ASC
LIMIT 10;
