
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459935 AND 2459936  
    GROUP BY 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity_sold,
        rs.total_sales_value,
        rs.ws_item_sk
    FROM 
        RankedSales rs
    INNER JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10  
)
SELECT 
    pi.i_item_id,
    pi.i_item_desc,
    pi.total_quantity_sold,
    pi.total_sales_value,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
FROM 
    PopularItems pi
LEFT JOIN 
    web_sales ws ON pi.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
GROUP BY 
    pi.i_item_id, pi.i_item_desc, pi.total_quantity_sold, pi.total_sales_value, ca.ca_city, ca.ca_state
ORDER BY 
    total_sales_value DESC  
LIMIT 20;
