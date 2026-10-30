
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
), SummarySales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_payment
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_item_sk
), AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        CASE 
            WHEN ca_state = 'NY' THEN 'Major City'
            WHEN ca_state = 'CA' AND ca_city LIKE '%Los Angeles%' THEN 'Major City'
            ELSE 'Other' 
        END AS location_type
    FROM customer_address
), NullHandling AS (
    SELECT 
        c_customer_sk,
        COALESCE(c_salutation, 'No Salutation') AS customer_salutation,
        cd_marital_status,
        hd_income_band_sk
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON hd_demo_sk = c_customer_sk
    WHERE (cd_marital_status IS NOT NULL OR hd_income_band_sk IS NULL)
), DetailedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM RankedReturns
    WHERE rnk = 1
    GROUP BY sr_item_sk
)
SELECT 
    S.ws_item_sk,
    S.total_quantity,
    S.total_net_profit,
    S.order_count,
    S.avg_payment,
    D.total_returned_quantity,
    D.total_returned_amount,
    A.ca_city,
    A.location_type,
    N.customer_salutation,
    N.cd_marital_status,
    CASE 
        WHEN S.total_net_profit > 1000 THEN 'High Profit'
        WHEN S.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM SummarySales S
LEFT JOIN DetailedReturns D ON S.ws_item_sk = D.sr_item_sk
JOIN AddressInfo A ON A.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer))
JOIN NullHandling N ON N.c_customer_sk = (SELECT MAX(c_customer_sk) FROM customer)
WHERE (S.total_net_profit IS NOT NULL OR D.total_returned_amount >= 100)
ORDER BY S.total_net_profit DESC, D.total_returned_quantity ASC
LIMIT 100 OFFSET 50;
