
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2022
        )
),
StoreSalesSummary AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS TotalStoreSales,
        COUNT(*) AS StoreSalesCount
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year > 1980
    GROUP BY
        ss.ss_item_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE
            WHEN hd.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 50000) THEN 'HighIncome'
            ELSE 'OtherIncome'
        END AS IncomeCategory
    FROM
        customer_demographics cd
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    s.s_store_id,
    COALESCE(RS.ws_sales_price, 0) AS WebSamplePrice,
    SSS.TotalStoreSales,
    CD.IncomeCategory,
    COUNT(DISTINCT RS.ws_order_number) AS UniqueWebOrders
FROM
    store s
LEFT JOIN
    RankedSales RS ON RS.ws_item_sk = s.s_store_sk
LEFT JOIN
    StoreSalesSummary SSS ON SSS.ss_item_sk = RS.ws_item_sk
JOIN
    CustomerDemographics CD ON CD.cd_demo_sk = s.s_store_sk
WHERE
    s.s_number_employees > 50
    OR s.s_floor_space < 1000
GROUP BY
    s.s_store_id, RS.ws_sales_price, SSS.TotalStoreSales, CD.IncomeCategory
HAVING
    COUNT(DISTINCT RS.ws_order_number) > 10
ORDER BY
    TotalStoreSales DESC, UniqueWebOrders DESC;
