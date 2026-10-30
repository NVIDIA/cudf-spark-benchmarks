
WITH  SalesCTE AS (
    SELECT
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM
        catalog_sales
    GROUP BY
        cs_sold_date_sk
    UNION ALL
    SELECT
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
),
SalesSummary AS (
    SELECT
        dd.d_date AS sale_date,
        COALESCE(SUM(s.total_sales), 0) AS total_sales,
        COALESCE(SUM(s.total_orders), 0) AS total_orders
    FROM
        date_dim dd
    LEFT JOIN (
        SELECT
            cs_sold_date_sk AS sold_date,
            total_sales,
            total_orders
        FROM
            SalesCTE
    ) s ON dd.d_date_sk = s.sold_date
    GROUP BY
        dd.d_date
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_ext_sales_price) AS sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM
        store_sales ss
    JOIN
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    ss.sale_date,
    ss.total_sales,
    ss.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.sales_total,
    cd.sales_count
FROM
    SalesSummary ss
LEFT JOIN
    CustomerDemographics cd ON ss.total_sales > 1000
WHERE
    ss.sale_date > DATE '2023-01-01'
ORDER BY
    ss.sale_date DESC,
    cd.cd_gender ASC, 
    cd.cd_marital_status DESC
LIMIT 100;
