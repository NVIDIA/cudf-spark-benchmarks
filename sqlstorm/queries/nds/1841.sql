
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate BETWEEN 500 AND 1500
),
ItemSalesSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    iss.i_product_name,
    iss.total_quantity_sold,
    iss.total_net_paid,
    r.sales_rank,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Purchase'
        WHEN r.sales_rank <= 5 THEN 'Top 5 Purchaser'
        ELSE 'Regular Purchaser' 
    END AS customer_category
FROM 
    CustomerInfo ci
JOIN 
    RankedSales r ON ci.c_customer_sk = r.ws_bill_customer_sk
JOIN 
    ItemSalesSummary iss ON r.ws_item_sk = iss.i_item_sk
WHERE 
    ci.ca_state IS NOT NULL
    AND (iss.total_net_paid >= 1000 OR iss.total_quantity_sold > 10)
ORDER BY 
    ci.ca_city, ci.ca_state, r.sales_rank;
