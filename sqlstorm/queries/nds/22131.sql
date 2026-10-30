
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        rd.income_bracket
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            hd.hd_demo_sk,
            CASE 
                WHEN ib.ib_lower_bound IS NULL THEN 'Undisclosed'
                ELSE CONCAT(CAST(ib.ib_lower_bound AS STRING), ' - ', CAST(ib.ib_upper_bound AS STRING))
            END AS income_bracket
        FROM household_demographics hd
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ) rd ON c.c_current_hdemo_sk = rd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(rs.total_profit) AS cumulative_profit,
        SUM(rs.total_quantity) AS cumulative_quantity,
        COUNT(DISTINCT rs.ws_bill_customer_sk) AS total_sales_count
    FROM CustomerDemographics cd
    JOIN RankedSales rs ON cd.c_customer_id = CAST(rs.ws_bill_customer_sk AS STRING)
    WHERE cd.cd_purchase_estimate IS NOT NULL
    GROUP BY cd.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
FilteredSales AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cumulative_profit DESC) AS rank_by_profit
    FROM SalesSummary
    WHERE cumulative_profit >= (SELECT AVG(cumulative_profit) FROM SalesSummary) 
      AND cumulative_quantity IS NOT NULL
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    CASE 
        WHEN f.cumulative_profit + COALESCE(f.total_sales_count, 0) > 10000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    f.cumulative_profit,
    f.cumulative_quantity,
    f.rank_by_profit
FROM FilteredSales f
WHERE f.rank_by_profit <= 10
ORDER BY f.c_customer_id;
