
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        SUM(ws.ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_country = 'USA' 
        AND i.i_current_price > 20.00 
        AND ws.ws_sold_date_sk BETWEEN 2458590 AND 2458597
    GROUP BY 
        ws.ws_item_sk, ws.ws_sales_price
),
SalesSummary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ranked_sales.total_quantity_sold,
        ranked_sales.ws_sales_price,
        RANK() OVER (ORDER BY ranked_sales.total_quantity_sold DESC) AS sales_rank
    FROM 
        RankedSales ranked_sales
    JOIN 
        item ON ranked_sales.ws_item_sk = item.i_item_sk
)
SELECT 
    ss.i_item_id, 
    ss.i_item_desc, 
    ss.total_quantity_sold, 
    ss.ws_sales_price, 
    ss.sales_rank
FROM 
    SalesSummary ss
WHERE 
    ss.sales_rank <= 10
ORDER BY 
    ss.sales_rank;
