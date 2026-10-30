
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid_inc_tax DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sold,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM catalog_sales cs
    INNER JOIN RankedSales rs ON cs.cs_item_sk = rs.ws_item_sk
    WHERE rs.rnk = 1
    GROUP BY cs.cs_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential,
    ss.total_sold,
    ss.total_sales_amount,
    ss.avg_net_profit
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.cs_item_sk
WHERE ss.total_sold >= 100 AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY ss.total_sales_amount DESC
LIMIT 10;
