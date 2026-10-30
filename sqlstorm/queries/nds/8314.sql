
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 100
    GROUP BY 
        ws.ws_item_sk
),
TopSalesItems AS (
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
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    (tsi.total_sales - SUM(cs.cs_ext_discount_amt)) AS net_sales_after_discount
FROM 
    TopSalesItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
LEFT JOIN 
    catalog_sales cs ON tsi.ws_item_sk = cs.cs_item_sk
GROUP BY 
    i.i_item_id, i.i_item_desc, tsi.total_quantity, tsi.total_sales
ORDER BY 
    net_sales_after_discount DESC;
