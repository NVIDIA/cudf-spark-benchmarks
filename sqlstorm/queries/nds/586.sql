
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_sales_price) AS total_sales,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 10
    GROUP BY 
        sd.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        SUM(cs.cs_ext_sales_price) AS gross_sales
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cus.c_customer_sk,
        c.total_orders,
        c.avg_net_profit,
        c.gross_sales
    FROM 
        CustomerStats c
    JOIN 
        customer cus ON c.c_customer_sk = cus.c_customer_sk
    WHERE 
        c.gross_sales > 5000
)
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    COUNT(DISTINCT s.ws_order_number) AS unique_sales_orders,
    SUM(s.ws_sales_price) AS total_revenue,
    SUM(COALESCE(s.ws_sales_price * 0.9, 0.0)) AS discount_revenue,
    COUNT(DISTINCT COALESCE(s.ws_order_number, 0)) AS order_count,
    AVG(sd.total_net_profit) AS avg_profit_per_order,
    dc.d_date AS sales_date
FROM 
    FilteredSales sd
JOIN 
    web_sales s ON s.ws_item_sk = sd.ws_item_sk
JOIN 
    customer c ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    date_dim dc ON s.ws_ship_date_sk = dc.d_date_sk
LEFT JOIN 
    HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE 
    dc.d_year = 2023
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, dc.d_date
HAVING 
    SUM(s.ws_sales_price) > 100
ORDER BY 
    total_revenue DESC;
