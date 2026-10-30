
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity, 
        sd.total_sales
    FROM 
        SalesData sd
    WHERE 
        sd.rank <= 10
)
SELECT 
    COALESCE(c.c_first_name, 'Unknown') AS customer_name,
    ca.ca_city,
    ts.total_quantity,
    ts.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ts.total_sales DESC) AS city_rank
FROM 
    TopSales ts
LEFT JOIN 
    web_sales ws ON ts.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
ORDER BY 
    ts.total_sales DESC, 
    ca.ca_city;
