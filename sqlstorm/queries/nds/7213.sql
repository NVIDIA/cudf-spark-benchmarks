
WITH SalesData AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        cs_item_sk
),
CustomerIncome AS (
    SELECT
        c.c_customer_sk,
        hd.hd_income_band_sk,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedSales AS (
    SELECT
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ci.hd_income_band_sk,
        ci.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ci.hd_income_band_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    JOIN CustomerIncome ci ON ci.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = sd.cs_item_sk
    )
)
SELECT
    rs.hd_income_band_sk,
    rs.cd_gender,
    COUNT(DISTINCT rs.cs_item_sk) AS item_count,
    SUM(rs.total_quantity) AS total_quantity_sold,
    SUM(rs.total_sales) AS total_revenue
FROM
    RankedSales rs
WHERE
    rs.sales_rank <= 10
GROUP BY
    rs.hd_income_band_sk,
    rs.cd_gender
ORDER BY
    rs.hd_income_band_sk,
    rs.cd_gender;
