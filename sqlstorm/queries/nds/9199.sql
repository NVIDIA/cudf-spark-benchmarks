WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500  
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSellingItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        RankedSales.total_quantity, 
        RankedSales.total_sales
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sales_rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers
FROM 
    TopSellingItems AS tsi
JOIN 
    customer AS c ON c.c_current_cdemo_sk IN (
        SELECT 
            cd.cd_demo_sk 
        FROM 
            customer_demographics AS cd
        WHERE 
            cd.cd_gender = 'F' 
            AND cd.cd_marital_status = 'M'
    )
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    tsi.i_item_id, tsi.i_item_desc, tsi.total_quantity, tsi.total_sales, ca.ca_city, ca.ca_state
ORDER BY 
    tsi.total_sales DESC;