
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerRegion AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, ca.ca_state
)
SELECT 
    cr.ca_state,
    SUM(ts.total_sales) AS total_revenue,
    AVG(cr.total_orders) AS avg_orders_per_customer
FROM 
    CustomerRegion cr
JOIN 
    TopSellingItems ts ON cr.c_customer_sk = ts.ws_item_sk
GROUP BY 
    cr.ca_state
ORDER BY 
    total_revenue DESC;
