
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
        AND cd.cd_marital_status = 'M'
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ts.total_quantity,
    ts.total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    TopSales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
JOIN 
    web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
GROUP BY 
    i.i_item_id, i.i_product_name, ts.total_quantity, ts.total_sales
ORDER BY 
    total_sales DESC, total_quantity DESC
LIMIT 10;
