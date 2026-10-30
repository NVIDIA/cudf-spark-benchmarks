
WITH ActiveCustomers AS (
    SELECT c_customer_sk, c_email_address, cd_gender, cd_marital_status, hd_income_band_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    WHERE c_current_addr_sk IS NOT NULL
),
SalesAggregates AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity
    FROM ActiveCustomers c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
SalesByGender AS (
    SELECT 
        ac.cd_gender,
        COUNT(sa.total_orders) AS customer_count,
        SUM(sa.total_net_profit) AS net_profit_sum,
        SUM(sa.total_quantity) AS quantity_sum,
        AVG(sa.total_net_profit) AS average_net_profit
    FROM SalesAggregates sa
    JOIN ActiveCustomers ac ON sa.c_customer_sk = ac.c_customer_sk
    GROUP BY ac.cd_gender
),
IncomeBandDistribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(ac.hd_income_band_sk) AS customer_count,
        SUM(sa.total_net_profit) AS total_net_profit
    FROM ActiveCustomers ac
    JOIN income_band ib ON ac.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN SalesAggregates sa ON ac.c_customer_sk = sa.c_customer_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    sbg.cd_gender,
    ibd.ib_income_band_sk,
    ibd.customer_count,
    ibd.total_net_profit,
    sbg.net_profit_sum,
    sbg.average_net_profit
FROM SalesByGender sbg
JOIN IncomeBandDistribution ibd ON sbg.customer_count > 50
ORDER BY sbg.cd_gender, ibd.ib_income_band_sk;
