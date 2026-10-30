
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ic.ib_lower_bound,
        ic.ib_upper_bound
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
),
SalesData AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_item_sk) AS total_sales
    FROM
        store_sales ss
    GROUP BY
        ss.ss_sold_date_sk, ss.ss_store_sk
)
SELECT
    a.full_address,
    a.ca_city,
    a.ca_state,
    c.customer_name,
    c.cd_gender,
    c.cd_marital_status,
    s.total_profit,
    s.total_sales
FROM
    AddressParts a
JOIN CustomerDetails c ON a.ca_address_sk = c.c_customer_sk
JOIN SalesData s ON s.ss_store_sk = a.ca_address_sk
ORDER BY
    s.total_profit DESC, c.customer_name;
