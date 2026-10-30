
WITH SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL 
        AND i.i_current_price > 0
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk AS item_sk, 
        total_sales,
        order_count
    FROM 
        SalesSummary
    WHERE 
        sales_rank <= 10
),
OrderDetails AS (
    SELECT 
        ts.item_sk,
        ts.total_sales,
        ts.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ci.c_first_name, 'Unknown') AS first_name,
        COALESCE(ci.c_last_name, 'Unknown') AS last_name,
        ca.ca_city,
        ca.ca_state
    FROM 
        TopSales ts
    LEFT JOIN 
        customer ci ON ts.item_sk = ci.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    od.first_name,
    od.last_name,
    od.cd_gender,
    od.cd_marital_status,
    od.ca_city,
    od.ca_state,
    SUM(od.total_sales) AS total_sales,
    SUM(od.order_count) AS total_orders
FROM 
    OrderDetails od
GROUP BY 
    od.first_name, od.last_name, od.cd_gender, od.cd_marital_status, od.ca_city, od.ca_state
HAVING 
    SUM(od.total_sales) > 10000
ORDER BY 
    total_sales DESC;
