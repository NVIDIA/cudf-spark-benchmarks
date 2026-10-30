
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50.00
    GROUP BY 
        ws.ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_orders,
        rs.total_sales,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_size
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
), 
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS customer_sales,
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        ws.ws_item_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, ws.ws_item_sk
)
SELECT 
    tsi.i_item_desc,
    tsi.i_brand,
    tsi.i_category,
    tsi.i_size,
    tsi.total_orders,
    tsi.total_sales,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_buyers,
    SUM(cs.customer_sales) AS total_customer_revenue
FROM 
    TopSellingItems tsi
JOIN 
    CustomerSales cs ON tsi.ws_item_sk = cs.ws_item_sk
GROUP BY 
    tsi.i_item_desc,
    tsi.i_brand,
    tsi.i_category,
    tsi.i_size,
    tsi.total_orders,
    tsi.total_sales
ORDER BY 
    total_sales DESC;
