
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        i.i_item_desc,
        i.i_category
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
SalesSummary AS (
    SELECT
        rs.i_category,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS item_count
    FROM
        RankedSales rs
    WHERE
        rs.sales_rank = 1
    GROUP BY
        rs.i_category
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND cd.cd_marital_status = 'M'
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesPerformance AS (
    SELECT
        cs.i_category,
        SUM(cs.total_sales) AS category_sales,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count,
        COALESCE(SUM(cd.total_profit), 0) AS total_profit_by_demographics
    FROM
        SalesSummary cs
    LEFT JOIN
        CustomerDemographics cd ON cd.total_profit > 0
    GROUP BY
        cs.i_category
)
SELECT
    sp.i_category,
    sp.category_sales,
    sp.demographic_count,
    sp.total_profit_by_demographics
FROM
    SalesPerformance sp
WHERE
    sp.category_sales > (SELECT AVG(category_sales) FROM SalesPerformance)
ORDER BY
    sp.category_sales DESC;
