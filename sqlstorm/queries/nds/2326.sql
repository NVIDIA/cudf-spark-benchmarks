
WITH SalesData AS (
    SELECT
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT DISTINCT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_cdemo_sk
),
TopCustomers AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS customer_rank
    FROM
        customer_demographics AS cd
    JOIN
        SalesData AS sd ON cd.cd_demo_sk = sd.customer_demo_sk
    WHERE
        cd.cd_purchase_estimate > 5000
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT tc.cd_demo_sk) AS number_of_top_customers,
    SUM(sd.total_quantity) AS total_quantity_purchased,
    SUM(sd.total_net_profit) AS total_profit
FROM
    TopCustomers AS tc
JOIN
    customer AS c ON tc.cd_demo_sk = c.c_current_cdemo_sk
JOIN
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    SalesData AS sd ON tc.cd_demo_sk = sd.customer_demo_sk
WHERE
    tc.customer_rank <= 100
GROUP BY
    ca.ca_city,
    ca.ca_state
ORDER BY
    total_profit DESC
LIMIT 10;
