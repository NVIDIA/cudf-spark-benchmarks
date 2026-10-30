
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
),
AggregateReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns 
    WHERE 
        cr_return_quantity IS NOT NULL
    GROUP BY 
        cr_item_sk
),
CustomerShippingInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
),
MaxSales AS (
    SELECT 
        r.ws_item_sk,
        MAX(r.ws_net_paid) AS max_net_paid
    FROM 
        RankedSales r
    WHERE 
        r.rank = 1
    GROUP BY 
        r.ws_item_sk
)
SELECT 
    s.ws_item_sk,
    s.ws_quantity,
    s.ws_net_paid,
    coalesce(a.total_returned, 0) AS total_returned,
    coalesce(a.total_return_amount, 0) AS total_return_amount,
    c.c_first_name,
    c.c_last_name,
    s.ws_net_paid / NULLIF(s.ws_quantity, 0) AS avg_sale_per_item
FROM 
    web_sales s 
LEFT JOIN 
    AggregateReturns a ON s.ws_item_sk = a.cr_item_sk
JOIN 
    CustomerShippingInfo c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    MaxSales m ON s.ws_item_sk = m.ws_item_sk
WHERE 
    s.ws_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 10 LIMIT 1)
    AND (s.ws_net_paid > m.max_net_paid OR a.total_return_amount < 100 OR c.city_rank = 1)
ORDER BY 
    s.ws_net_paid DESC
LIMIT 100;
