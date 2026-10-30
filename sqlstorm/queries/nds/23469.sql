
WITH  AddressTree AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_reason_sk,
        COALESCE(sr_reason_sk, 0) AS reason_id, 
        CASE 
            WHEN sr_return_quantity < 0 THEN 'negative'
            WHEN sr_return_quantity = 0 THEN 'zero'
            ELSE 'positive'
        END AS return_value
    FROM store_returns
    WHERE sr_customer_sk IS NOT NULL
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    (SELECT COUNT(*) 
      FROM CustomerReturns cr 
      WHERE cr.sr_customer_sk = c.c_customer_sk AND cr.return_value = 'positive') AS positive_returns,
    (SELECT COUNT(*) 
      FROM CustomerReturns cr 
      WHERE cr.sr_customer_sk = c.c_customer_sk AND cr.return_value = 'negative') AS negative_returns,
    (SELECT MAX(total_net_paid) 
      FROM WebSalesSummary wss 
      WHERE wss.ws_bill_customer_sk = c.c_customer_sk) AS max_web_sales,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
FROM customer c
LEFT JOIN AddressTree ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE c.c_birth_year BETWEEN 1960 AND 1990
  AND (cd.cd_gender = 'F' OR cd.cd_marital_status IS NULL)
  AND EXISTS (SELECT 1 
                FROM WebSalesSummary 
                WHERE ws_bill_customer_sk = c.c_customer_sk AND total_sales > 10000)
ORDER BY rank_by_estimate, c.c_customer_id;
