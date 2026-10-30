
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COUNT(rws.ws_order_number) AS total_orders,
        SUM(rws.ws_quantity) AS total_quantity,
        SUM(rws.ws_sales_price * rws.ws_quantity) AS total_sales,
        AVG(rws.ws_sales_price) AS avg_price
    FROM 
        RankedSales rws
    JOIN 
        item ON rws.ws_item_sk = item.i_item_sk
    WHERE 
        rws.rn = 1
    GROUP BY 
        item.i_item_id, item.i_product_name
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        SUM(cs.cs_sales_price) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_catalog_orders,
        cs.total_catalog_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_catalog_sales DESC) AS rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_catalog_sales > 1000
)
SELECT 
    s.i_item_id AS item_id,
    s.i_product_name AS product_name,
    s.total_orders,
    s.total_quantity,
    s.total_sales,
    s.avg_price,
    hvc.c_customer_id AS customer_id,
    hvc.total_catalog_orders,
    hvc.total_catalog_sales
FROM 
    SalesSummary s
JOIN 
    HighValueCustomers hvc ON s.total_orders > 5
ORDER BY 
    s.total_sales DESC, hvc.total_catalog_sales DESC
LIMIT 100;
