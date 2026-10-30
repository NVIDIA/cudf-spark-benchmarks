
WITH  SalesCTE AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 365 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
CustomerCTE AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(ROUND(cd.cd_purchase_estimate / NULLIF(ib.ib_upper_bound, 0), 2), 0) AS relative_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_current_addr_sk IS NOT NULL 
    AND cd.cd_purchase_estimate > 0
),
FinalSales AS (
    SELECT
        cu.c_customer_sk,
        cu.c_first_name,
        cu.c_last_name,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_purchase_estimate,
        cu.relative_purchase_estimate,
        s.total_orders,
        s.total_profit
    FROM CustomerCTE cu
    JOIN SalesCTE s ON cu.c_customer_sk = s.ws_bill_customer_sk
    WHERE s.total_orders IS NOT NULL AND s.sales_rank <= 10
)
SELECT
    fs.*,
    CASE
        WHEN fs.total_profit > 10000 THEN 'High Value Customer'
        WHEN fs.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    CONCAT(fs.c_first_name, ' ', fs.c_last_name) AS full_name,
    CASE
        WHEN fs.cd_gender IS NULL THEN 'Unknown'
        ELSE fs.cd_gender
    END AS gender_display
FROM FinalSales fs
ORDER BY fs.total_profit DESC, fs.relative_purchase_estimate DESC
LIMIT 100;
