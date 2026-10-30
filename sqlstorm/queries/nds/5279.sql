
WITH SalesDetails AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2450102 AND 2450766 
    GROUP BY
        ws_bill_customer_sk,
        ws_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesAnalysis AS (
    SELECT
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        SUM(si.total_quantity) AS total_quantity,
        SUM(si.total_sales) AS total_sales,
        SUM(si.total_discount) AS total_discount,
        SUM(si.total_profit) AS total_profit,
        COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
        AVG(si.total_sales) AS average_sales_per_customer,
        AVG(si.total_profit) AS average_profit_per_customer
    FROM
        SalesDetails si
    JOIN CustomerInfo ci ON si.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY
        ci.ca_city,
        ci.ca_state,
        ci.ca_country
)
SELECT
    sa.ca_city,
    sa.ca_state,
    sa.ca_country,
    sa.customer_count,
    sa.total_quantity,
    sa.total_sales,
    sa.total_discount,
    sa.total_profit,
    sa.average_sales_per_customer,
    sa.average_profit_per_customer
FROM
    SalesAnalysis sa
ORDER BY
    sa.total_sales DESC
LIMIT 100;
