WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND i.i_current_price BETWEEN 10.00 AND 100.00
        AND (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c.c_birth_year) BETWEEN 18 AND 35
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    tsi.total_quantity,
    tsi.total_sales,
    (SELECT SUM(total_sales) FROM TopSellingItems) AS overall_sales
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
ORDER BY 
    tsi.total_sales DESC
LIMIT 10;