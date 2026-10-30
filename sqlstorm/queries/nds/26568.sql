
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS Full_Street_Address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_customer_sk
    FROM web_sales ws
    WHERE ws.ws_sales_price > 50
),
AggregatedSales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS Total_Quantity_Sold,
        SUM(sd.ws_net_profit) AS Total_Profit
    FROM SalesData sd
    GROUP BY sd.ws_item_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    ad.Full_Street_Address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    asales.Total_Quantity_Sold,
    asales.Total_Profit
FROM CustomerDetails cd
JOIN customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN AddressDetails ad ON ad.ca_address_sk = ca.ca_address_sk
JOIN AggregatedSales asales ON asales.ws_item_sk = cd.c_customer_sk
WHERE cd.cd_gender = 'M' AND cd.cd_purchase_estimate > 1000
ORDER BY asales.Total_Profit DESC
LIMIT 100;
