
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        dd.d_year,
        dd.d_month_seq,
        s.s_store_id,
        sm.sm_type
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        store s ON ws.ws_bill_addr_sk = s.s_store_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        cd.cd_gender = 'F'
        AND dd.d_year = 2022
        AND dd.d_month_seq BETWEEN 1 AND 6
), AggregatedSales AS (
    SELECT 
        ca_state,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS average_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        SalesData
    GROUP BY 
        ca_state
)
SELECT 
    ca_state,
    total_quantity,
    total_sales,
    average_sales_price,
    total_orders,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    AggregatedSales
WHERE 
    total_quantity > 1000
ORDER BY 
    sales_rank
LIMIT 10;
