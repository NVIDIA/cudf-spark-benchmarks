
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COALESCE(cd.cd_education_status, 'Undefined') AS education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'Not Rated') AS credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, 
        full_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        hd.hd_buy_potential
),
RankedCustomers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_orders DESC) AS rank_within_state
    FROM CustomerData
)
SELECT 
    full_name,
    gender,
    marital_status,
    education_status,
    purchase_estimate,
    credit_rating,
    income_band_sk,
    ca_city,
    ca_state,
    ca_country,
    hd_buy_potential,
    total_orders,
    rank_within_state
FROM RankedCustomers
WHERE rank_within_state <= 10
ORDER BY ca_state, total_orders DESC;
