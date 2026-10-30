
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_sales_price) AS total_sales_value,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk, 
        total_quantity_sold, 
        total_sales_value
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    i.i_item_id, 
    i.i_product_name, 
    tsi.total_quantity_sold, 
    tsi.total_sales_value, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
FROM 
    item i
JOIN 
    TopSellingItems tsi ON i.i_item_sk = tsi.ws_item_sk
JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    tsi.total_sales_value DESC;
