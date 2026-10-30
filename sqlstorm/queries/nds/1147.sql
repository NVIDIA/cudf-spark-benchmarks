
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) as rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sales.ws_item_sk,
        sales.total_quantity,
        sales.total_net_paid,
        sales.avg_sales_price,
        sales.total_discount
    FROM 
        SalesData sales
    WHERE 
        sales.rank <= 10
),
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_category,
        COALESCE(SUM(CASE WHEN inv.inv_quantity_on_hand IS NOT NULL THEN inv.inv_quantity_on_hand ELSE 0 END), 0) AS total_inventory
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
)
SELECT 
    t_item_details.i_item_sk,
    t_item_details.i_item_desc,
    t_item_details.i_brand,
    t_item_details.i_category,
    t_sales.total_quantity,
    t_sales.total_net_paid,
    t_sales.avg_sales_price,
    t_sales.total_discount,
    COALESCE(t_item_details.total_inventory, 0) AS available_inventory
FROM 
    ItemDetails t_item_details
JOIN 
    TopSales t_sales ON t_item_details.i_item_sk = t_sales.ws_item_sk
ORDER BY 
    t_sales.total_net_paid DESC;
