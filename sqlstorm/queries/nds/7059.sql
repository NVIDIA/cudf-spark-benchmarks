
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name,
        sales.total_sales
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 10
),
CustomerSummary AS (
    SELECT 
        customer.c_customer_id,
        COUNT(DISTINCT web_sales.ws_order_number) AS total_orders,
        SUM(web_sales.ws_quantity) AS total_items_purchased
    FROM 
        customer
    JOIN 
        web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
    GROUP BY 
        customer.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.total_items_purchased,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_sales
FROM 
    CustomerSummary cs
JOIN 
    TopItems ti ON cs.total_orders > 5
ORDER BY 
    cs.total_items_purchased DESC, ti.total_sales DESC
LIMIT 50;
