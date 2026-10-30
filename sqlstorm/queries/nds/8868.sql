
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesByState AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_sales) AS state_sales,
        SUM(cs.total_orders) AS state_orders
    FROM 
        CustomerSales cs
    JOIN 
        customer_address ca ON cs.c_customer_id = ca.ca_address_id
    GROUP BY 
        ca.ca_state
),
RankedSales AS (
    SELECT 
        ca_state,
        state_sales,
        state_orders,
        RANK() OVER (ORDER BY state_sales DESC) AS sales_rank
    FROM 
        SalesByState
)
SELECT 
    rs.ca_state,
    rs.state_sales,
    rs.state_orders,
    rs.sales_rank
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.sales_rank;
