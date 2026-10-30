
WITH AddressCount AS (
    SELECT
        ca_city,
        COUNT(*) AS address_count
    FROM
        customer_address
    GROUP BY
        ca_city
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
ExtendedSales AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS total_orders
    FROM
        catalog_sales
    GROUP BY
        cs_bill_customer_sk
),
FinalSummary AS (
    SELECT
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(ws.total_profit, 0) + COALESCE(cs.total_profit, 0) AS total_profit,
        COALESCE(ws.total_orders, 0) + COALESCE(cs.total_orders, 0) AS total_orders
    FROM
        CustomerDetails cd
    LEFT JOIN
        SalesSummary ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        ExtendedSales cs ON cd.c_customer_sk = cs.cs_bill_customer_sk
)
SELECT
    fa.full_name,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.cd_education_status,
    fa.total_profit,
    fa.total_orders,
    ac.address_count
FROM
    FinalSummary fa
JOIN
    AddressCount ac ON fa.full_name IS NOT NULL
ORDER BY
    fa.total_profit DESC, fa.total_orders DESC
LIMIT 10;
