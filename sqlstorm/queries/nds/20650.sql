
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year) AS city_birth_year_rank
    FROM customer c 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROUND(AVG(ws_net_paid_inc_tax), 2) AS avg_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
TopReturningCustomers AS (
    SELECT 
        rwr.wr_returning_customer_sk,
        rwr.total_returned,
        cs.total_quantity_sold,
        cs.order_count,
        cs.avg_net_paid
    FROM RankedReturns rwr 
    JOIN SalesSummary cs ON rwr.wr_returning_customer_sk = cs.ws_bill_customer_sk
    WHERE rwr.return_rank = 1
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    td.total_returned,
    td.total_quantity_sold,
    td.order_count,
    td.avg_net_paid,
    COALESCE(CASE 
        WHEN cd.city_birth_year_rank = 1 THEN cd.ca_city 
        ELSE 'Other City' 
    END, 'Unknown City') AS city_rank_status
FROM TopReturningCustomers td
JOIN CustomerDetails cd ON td.wr_returning_customer_sk = cd.c_customer_sk
WHERE td.avg_net_paid > 100 
    AND cd.cd_marital_status IS NOT NULL 
    AND (cd.cd_credit_rating LIKE '%good%' OR cd.cd_credit_rating IS NULL)
ORDER BY td.total_returned DESC, td.avg_net_paid ASC
LIMIT 10;
