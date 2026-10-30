
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
    GROUP BY 
        ws.ws_item_sk
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales,
    (COALESCE(ts.total_sales, 0) / NULLIF(SUM(CASE WHEN inv.inv_date_sk IS NOT NULL THEN inv.inv_quantity_on_hand END), 0)) AS sales_per_inventory
FROM 
    item it
LEFT JOIN 
    TopSales ts ON it.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    inventory inv ON it.i_item_sk = inv.inv_item_sk
WHERE 
    it.i_current_price > 20.00
GROUP BY 
    it.i_item_id, it.i_item_desc, ts.total_quantity, ts.total_sales
ORDER BY 
    total_sales DESC;
