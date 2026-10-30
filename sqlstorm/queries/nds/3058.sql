
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
HighSalesItems AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.ws_sales_price) AS max_sales_price,
        COUNT(rs.ws_quantity) AS sale_count
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        COUNT(rs.ws_quantity) > 10
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IS NOT NULL AND
        ca.ca_state IS NOT NULL
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    hi.ws_item_sk,
    hi.max_sales_price,
    hi.sale_count,
    COALESCE(ta.total_returns, 0) AS total_returns,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    CASE 
        WHEN hi.sale_count > 15 AND COALESCE(ta.total_returns, 0) > 5 THEN 'High Performance Item'
        WHEN hi.sale_count <= 15 AND COALESCE(ta.total_returns, 0) > 5 THEN 'Average Performance Item'
        ELSE 'Low Performance Item'
    END AS performance_category
FROM 
    HighSalesItems hi
LEFT JOIN 
    TotalReturns ta ON hi.ws_item_sk = ta.cr_item_sk
JOIN 
    CustomerAddress ca ON ca.ca_city LIKE '%town%'
ORDER BY 
    hi.max_sales_price DESC
LIMIT 50;
