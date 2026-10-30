WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451921 AND 2452104 
),
AggregateReturns AS (
    SELECT 
        cr.cr_item_sk, 
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ws.ws_quantity) AS total_sold,
    AVG(CASE WHEN r.total_returns IS NOT NULL THEN r.total_returns ELSE 0 END) AS avg_returns,
    AVG(cd.avg_purchase_estimate) AS avg_purchase_by_gender
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN AggregateReturns r ON r.cr_item_sk = ws.ws_item_sk
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE ca.ca_city LIKE 'San%' AND ca.ca_state = 'CA' 
GROUP BY ca.ca_address_id, ca.ca_city
HAVING SUM(ws.ws_quantity) > 100
ORDER BY total_customers DESC, avg_returns DESC;