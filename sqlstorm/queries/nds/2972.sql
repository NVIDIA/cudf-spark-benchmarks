
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_quantity > 0
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM
        SalesData sd
    WHERE
        sd.rn <= 5
    GROUP BY
        sd.ws_item_sk
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent,
        MAX(cd.cd_purchase_estimate) AS purchase_estimate
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk
),
IncomeAnalysis AS (
    SELECT
        h.hd_income_band_sk,
        AVG(cs.cs_net_profit) AS avg_net_profit
    FROM
        household_demographics h
    JOIN
        catalog_sales cs ON h.hd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY
        h.hd_income_band_sk
),
FinalResults AS (
    SELECT
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        ia.avg_net_profit
    FROM
        CustomerSummary cs
    LEFT JOIN
        IncomeAnalysis ia ON cs.total_spent > ia.avg_net_profit
)
SELECT
    r.ca_state,
    COUNT(DISTINCT fr.c_customer_sk) AS unique_customers,
    COALESCE(SUM(fr.total_spent), 0) AS total_spent,
    COALESCE(AVG(fr.avg_net_profit), 0) AS avg_net_profit_in_state
FROM
    customer_address r
LEFT JOIN
    FinalResults fr ON r.ca_address_sk = fr.c_customer_sk
GROUP BY
    r.ca_state
ORDER BY
    total_spent DESC, unique_customers DESC;
