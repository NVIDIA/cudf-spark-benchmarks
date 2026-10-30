
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM
        customer_demographics
),
CustomerAddresses AS (
    SELECT
        c.c_customer_sk,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM
        customer AS c
    JOIN
        customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(DISTINCT rs.ws_bill_customer_sk) AS customer_count,
    AVG(rs.total_sales) AS avg_sales,
    SUM(rs.order_count) AS total_orders,
    cd.cd_gender,
    cd.cd_marital_status
FROM
    RankedSales AS rs
JOIN
    CustomerAddresses AS ca ON rs.ws_bill_customer_sk = ca.c_customer_sk
JOIN
    CustomerDemographics AS cd ON rs.ws_bill_customer_sk = cd.cd_demo_sk
WHERE
    rs.rank <= 10
GROUP BY
    ca.ca_city, ca.ca_state, ca.ca_country, cd.cd_gender, cd.cd_marital_status
ORDER BY
    customer_count DESC
LIMIT 20;
