
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rn,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY') 
        AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
MaxSales AS (
    SELECT 
        ws_order_number,
        MAX(ws_sales_price) as max_sales_price,
        SUM(ws_quantity) as total_quantity
    FROM 
        RankedSales
    WHERE 
        rn = 1
    GROUP BY 
        ws_order_number
),
SalesSummary AS (
    SELECT 
        ms.ws_order_number,
        ms.max_sales_price,
        s.total_quantity,
        CASE 
            WHEN ms.max_sales_price IS NULL THEN 'Price Unavailable'
            WHEN s.total_quantity > 100 THEN 'High Volume'
            ELSE 'Regular Volume' 
        END as sales_category
    FROM 
        MaxSales ms
    LEFT JOIN 
        (SELECT 
             ws_order_number, 
             SUM(ws_quantity) as total_quantity
         FROM 
             web_sales
         GROUP BY 
             ws_order_number) s ON ms.ws_order_number = s.ws_order_number
)
SELECT 
    COUNT(*) as total_orders,
    AVG(max_sales_price) as avg_max_sales_price,
    SUM(CASE WHEN sales_category = 'High Volume' THEN 1 ELSE 0 END) as high_volume_orders,
    MIN(max_sales_price) as min_max_sales_price,
    MAX(max_sales_price) as max_max_sales_price
FROM 
    SalesSummary;
