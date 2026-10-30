
WITH RankedSales AS (
    SELECT
        ws_web_page_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_web_page_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2451545 AND 2451560
    GROUP BY
        ws_web_page_sk
),
TopSales AS (
    SELECT
        wp.wp_web_page_id,
        wp.wp_url,
        rs.total_sales,
        rs.order_count
    FROM
        RankedSales rs
    JOIN
        web_page wp ON rs.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        rs.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_first_shipto_date_sk BETWEEN 2451545 AND 2451560
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    ts.wp_web_page_id,
    ts.wp_url,
    ts.total_sales,
    ts.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count
FROM
    TopSales ts
LEFT JOIN
    CustomerDemographics cd ON 1=1
ORDER BY
    ts.total_sales DESC, cd.customer_count DESC;
