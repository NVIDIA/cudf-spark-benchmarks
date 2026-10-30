
WITH AddressInfo AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        ca_country
    FROM
        customer_address
    WHERE
        ca_country = 'USA'
),
DemographicsInfo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM
        customer_demographics
    WHERE
        cd_gender = 'F' AND cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.city_state_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_credit_rating,
        s.total_net_profit,
        s.order_count
    FROM
        customer c
    JOIN
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN
        DemographicsInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN
        SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT
    full_address,
    city_state_zip,
    ca_country,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_credit_rating,
    total_net_profit,
    order_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM
    CombinedData
WHERE
    total_net_profit IS NOT NULL
ORDER BY
    total_net_profit DESC;
