
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM
        web_sales ws
),
TotalReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    ca.ca_country,
    SUM(COALESCE(RankedSales.ws_sales_price, 0) * COALESCE(RankedSales.ws_quantity, 0)) AS total_sales,
    COUNT(DISTINCT CASE WHEN RankedSales.sales_rank = 1 THEN RankedSales.ws_item_sk END) AS best_selling_items,
    COUNT(DISTINCT cd.cd_demo_sk) AS total_customers,
    AVG(COALESCE(TR.total_returned, 0)) AS avg_returns_per_item
FROM
    customer_address ca
LEFT JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN
    RankedSales ON c.c_customer_sk = RankedSales.ws_item_sk
LEFT JOIN
    TotalReturns TR ON TR.wr_item_sk = RankedSales.ws_item_sk
JOIN
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    ca.ca_country IS NOT NULL
GROUP BY
    ca.ca_country
ORDER BY
    total_sales DESC
LIMIT 10;
