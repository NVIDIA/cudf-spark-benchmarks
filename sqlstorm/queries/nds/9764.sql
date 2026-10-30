
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq <= 6)
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq <= 12)
    GROUP BY
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer_demographics cd
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id IN (
        SELECT c.c_customer_id
        FROM customer c
        WHERE c.c_current_cdemo_sk = cd.cd_demo_sk
    )
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
