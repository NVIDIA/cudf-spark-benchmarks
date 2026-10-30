
WITH SalesSummary AS (
    SELECT
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        d.d_year, sm.sm_type
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
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
),
FinalReport AS (
    SELECT
        ss.d_year,
        ss.sm_type,
        ss.total_quantity,
        ss.total_sales,
        ss.total_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.customer_count
    FROM
        SalesSummary ss
    JOIN
        CustomerDemographics cd ON ss.d_year = (SELECT MAX(d_year) FROM SalesSummary)
    ORDER BY
        ss.total_sales DESC
)
SELECT
    * 
FROM 
    FinalReport
WHERE
    customer_count > 100
LIMIT 50;
