
WITH AddressInfo AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_zip,
        ca_city,
        ca_state,
        ca_country,
        ca_address_sk
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateInfo AS (
    SELECT 
        d.d_date_sk,
        d.d_date AS purchase_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
    WHERE d.d_year = 2023
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        wi.full_address,
        ci.full_name,
        di.purchase_date,
        di.d_day_name
    FROM web_sales ws
    JOIN AddressInfo wi ON ws.ws_bill_addr_sk = wi.ca_address_sk
    JOIN CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN DateInfo di ON ws.ws_sold_date_sk = di.d_date_sk
)
SELECT
    full_address,
    full_name,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_net_paid_inc_tax) AS total_amount,
    SUM(ws_net_profit) AS total_profit,
    d_day_name
FROM SalesData
GROUP BY full_address, full_name, d_day_name
HAVING SUM(ws_net_paid_inc_tax) > 1000
ORDER BY total_profit DESC, total_quantity DESC;
