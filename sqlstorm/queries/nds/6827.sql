
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
AggregatedSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items
    FROM 
        RankedSales rs
    WHERE 
        rs.item_rank <= 5
    GROUP BY 
        rs.ws_order_number
)
SELECT 
    asales.ws_order_number,
    asales.total_sales_value,
    asales.unique_items,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    AggregatedSales asales
JOIN 
    web_sales ws ON asales.ws_order_number = ws.ws_order_number
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    asales.total_sales_value DESC
LIMIT 10;
