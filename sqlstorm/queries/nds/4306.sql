
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_sold_date_sk,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01')
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr_order_number) AS total_returned_orders
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01')
    GROUP BY 
        wr_returning_customer_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    ca.ca_address_id,
    c.c_customer_id,
    COALESCE(cu.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cu.total_returned_orders, 0) AS total_returned_orders,
    COALESCE(irs.total_quantity_on_hand, 0) AS quantity_available,
    MAX(rs.ws_sales_price) AS max_web_sales_price
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cu ON c.c_customer_sk = cu.wr_returning_customer_sk
LEFT JOIN 
    InventoryStatus irs ON irs.inv_item_sk IN (
        SELECT 
            rs.ws_item_sk
        FROM 
            RankedSales rs
        WHERE 
            rs.price_rank = 1
    )
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk IN (
        SELECT 
            rs.ws_item_sk
        FROM 
            RankedSales rs
        WHERE 
            rs.price_rank = 1
    )
WHERE 
    ca.ca_state = 'NY'
GROUP BY 
    ca.ca_address_id, 
    c.c_customer_id, 
    cu.total_returned_quantity, 
    cu.total_returned_orders, 
    irs.total_quantity_on_hand
ORDER BY 
    max_web_sales_price DESC;
