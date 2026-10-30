
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ri.total_quantity_sold,
        ri.total_sales,
        ri.total_orders
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    WHERE 
        ri.sales_rank <= 10
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS customer_total_spent,
        COUNT(DISTINCT ws_order_number) AS customer_order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    ci.total_quantity_sold,
    ci.total_sales,
    cs.c_customer_id,
    cs.customer_total_spent,
    cs.customer_order_count
FROM 
    TopItems ci
JOIN 
    CustomerSales cs 
ON 
    cs.customer_order_count > 5
ORDER BY 
    ci.total_sales DESC, 
    cs.customer_total_spent DESC;
