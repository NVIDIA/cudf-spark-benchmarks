WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '1 year')
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_price = 1
        AND rs.total_quantity > 100
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
SalesSummary AS (
    SELECT 
        fa.ws_item_sk,
        SUM(fa.ws_sales_price * fa.ws_quantity) AS total_revenue,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        FilteredSales fa
    LEFT JOIN CustomerAddress ca ON fa.ws_order_number = ca.ca_address_sk
    GROUP BY 
        fa.ws_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_revenue,
    fs.address_count,
    CASE 
        WHEN fs.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    SalesSummary fs
WHERE 
    fs.total_revenue > 1000
ORDER BY 
    sales_status DESC,
    fs.total_revenue DESC;