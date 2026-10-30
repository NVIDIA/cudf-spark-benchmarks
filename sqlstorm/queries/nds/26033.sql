
WITH CustomerAddressDetails AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM
        customer_address
),
CustomerDemographicsDetails AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_profile
    FROM
        customer_demographics
),
WebSalesAggregate AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
CustomerAnalytics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ad.ca_city AS city,
        ad.ca_state AS state,
        ad.ca_zip AS zip,
        demographics.demographic_profile,
        COALESCE(ws.total_spent, 0) AS total_spent,
        COALESCE(ws.total_orders, 0) AS total_orders,
        COALESCE(ws.avg_profit, 0) AS avg_profit
    FROM
        customer c
    LEFT JOIN CustomerAddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    LEFT JOIN CustomerDemographicsDetails demographics ON c.c_current_cdemo_sk = demographics.cd_demo_sk
    LEFT JOIN WebSalesAggregate ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.city,
    c.state,
    c.zip,
    c.total_spent,
    c.total_orders,
    c.avg_profit,
    CASE 
        WHEN c.total_spent > 1000 THEN 'High Value Customer'
        WHEN c.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_segment
FROM
    CustomerAnalytics c
WHERE
    c.state = 'CA'
ORDER BY
    c.total_spent DESC;
