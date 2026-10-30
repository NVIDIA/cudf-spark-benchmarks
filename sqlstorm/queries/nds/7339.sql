
WITH SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_sold_date_sk) AS days_sold
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk,
        ws_item_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopItems AS (
    SELECT
        s.ws_item_sk,
        SUM(s.total_sales) AS item_total_sales
    FROM
        SalesSummary s
    GROUP BY
        s.ws_item_sk
    ORDER BY
        item_total_sales DESC
    LIMIT 10
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(ss.total_sales) AS total_sales,
    SUM(ss.total_profit) AS total_profit,
    AVG(ss.days_sold) AS avg_days_sold
FROM
    SalesSummary ss
JOIN
    CustomerDemographics cd ON ss.ws_bill_customer_sk = cd.c_customer_sk
JOIN
    TopItems ti ON ss.ws_item_sk = ti.ws_item_sk
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
ORDER BY
    total_sales DESC;
