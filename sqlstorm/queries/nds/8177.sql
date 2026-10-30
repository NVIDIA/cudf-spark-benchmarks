
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND i.i_current_price > 50
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    t.total_quantity,
    t.total_sales,
    a.ca_city,
    a.ca_state,
    a.ca_country
FROM 
    TopSales t
JOIN 
    customer c ON t.ws_item_sk = c.c_customer_sk
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE 
    a.ca_state IN ('CA', 'NY', 'TX') 
ORDER BY 
    t.total_sales DESC;
