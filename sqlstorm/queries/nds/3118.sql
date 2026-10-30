
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        ws_bill_customer_sk,
        ws_ship_date_sk
),
HighProfitCustomers AS (
    SELECT
        customer.c_customer_sk,
        customer.c_first_name,
        customer.c_last_name,
        customer.c_email_address,
        RankedSales.total_net_profit
    FROM
        customer
    JOIN
        RankedSales ON customer.c_customer_sk = RankedSales.ws_bill_customer_sk
    WHERE
        RankedSales.profit_rank = 1
),
StoreSalesSummary AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_store_net_profit
    FROM
        store_sales
    GROUP BY
        ss_store_sk
)
SELECT
    HPC.c_customer_sk,
    HPC.c_first_name,
    HPC.c_last_name,
    HPC.c_email_address,
    COALESCE(SSS.total_store_net_profit, 0) AS total_store_net_profit,
    HPC.total_net_profit,
    CASE 
        WHEN HPC.total_net_profit > COALESCE(SSS.total_store_net_profit, 0) THEN 'Customer profits exceed store profits'
        ELSE 'Store profits exceed or equal to customer profits'
    END AS profit_comparison
FROM
    HighProfitCustomers HPC
LEFT JOIN
    StoreSalesSummary SSS ON SSS.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_store_id = 'ST0001')
WHERE
    HPC.total_net_profit IS NOT NULL
ORDER BY
    HPC.total_net_profit DESC
LIMIT 10;
