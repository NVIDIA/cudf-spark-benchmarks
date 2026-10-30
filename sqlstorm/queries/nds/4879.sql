
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_ship_mode_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAggregate AS (
    SELECT 
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(cd.gender, 'Not Specified') AS customer_gender,
    ra.total_quantity,
    ra.total_sales,
    sa.total_store_sales,
    sa.avg_net_paid,
    CASE 
        WHEN ra.total_sales > (SELECT AVG(total_sales) FROM RankedSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance,
    RANK() OVER (ORDER BY ra.total_sales DESC) AS sales_rank
FROM customer_address ca
LEFT JOIN CustomerDetails cd ON ca.ca_address_sk = cd.c_customer_sk
LEFT JOIN RankedSales ra ON cd.c_customer_sk = ra.ws_item_sk
CROSS JOIN SalesAggregate sa
WHERE ca.ca_country = 'USA'
AND (cd.cd_marital_status = 'S' OR cd.cd_purchase_estimate > 1000)
GROUP BY ca.ca_city, ca.ca_state, cd.gender, ra.total_quantity, ra.total_sales, sa.total_store_sales, sa.avg_net_paid
ORDER BY ra.total_sales DESC
LIMIT 100;
