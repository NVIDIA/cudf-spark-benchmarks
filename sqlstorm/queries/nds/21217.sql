
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT customer_id, total_profit
    FROM RankedSales
    WHERE rank = 1 AND total_profit IS NOT NULL
),
CustomerDemographic AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        GREATEST(ws.ws_net_paid, 0) AS net_paid_positive,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), NULL) AS ext_discount_amt,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN HighValueCustomers hvc ON ws.ws_bill_customer_sk = hvc.customer_id
),
CustomerAddresses AS (
    SELECT DISTINCT
        ca.ca_address_sk,
        ca.ca_country,
        ca.ca_city,
        CASE 
            WHEN ca.ca_state IS NULL THEN 'Unknown State'
            ELSE ca.ca_state 
        END AS state_info
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE c.c_customer_sk IS NOT NULL
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    SUM(sd.ws_sales_price) AS total_sales,
    AVG(sd.net_paid_positive) AS average_net_paid,
    COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
    COUNT(DISTINCT sd.ws_item_sk) FILTER (WHERE sd.ext_discount_amt IS NOT NULL) AS items_with_discount
FROM SalesData sd
JOIN CustomerDemographic cd ON sd.ws_item_sk IN (
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_current_price < (SELECT AVG(i2.i_current_price) FROM item i2)
)
LEFT JOIN CustomerAddresses ca ON ca.ca_city = 'New York'
WHERE sd.ws_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING COUNT(sd.ws_item_sk) > 5 AND AVG(sd.ws_sales_price) IS NOT NULL
ORDER BY total_sales DESC, cd.cd_gender DESC;
