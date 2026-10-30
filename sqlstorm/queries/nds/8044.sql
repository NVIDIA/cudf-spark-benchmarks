
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_orders_returned,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighReturnCustomers AS (
    SELECT 
        rr.wr_returning_customer_sk,
        rr.total_returned_quantity,
        rr.total_return_amount,
        cd.cd_gender,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country
    FROM RankedReturns rr
    JOIN CustomerDemographics cd ON rr.wr_returning_customer_sk = cd.cd_demo_sk
    WHERE rr.return_rank <= 10
)
SELECT 
    HRC.ca_city,
    HRC.ca_state,
    HRC.ca_country,
    HRC.cd_gender,
    COUNT(*) AS num_high_return_customers,
    SUM(HRC.total_returned_quantity) AS total_returned_quantity,
    SUM(HRC.total_return_amount) AS total_return_amount
FROM HighReturnCustomers HRC
GROUP BY 
    HRC.ca_city, 
    HRC.ca_state, 
    HRC.ca_country, 
    HRC.cd_gender
ORDER BY total_return_amount DESC
LIMIT 5;
