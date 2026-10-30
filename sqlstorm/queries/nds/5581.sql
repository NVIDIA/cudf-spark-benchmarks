
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(cs.cs_order_number) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND i.i_current_price BETWEEN 10 AND 500
    GROUP BY 
        cs.cs_item_sk
),
TopProfitableItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        RankedSales.total_sales,
        RankedSales.total_net_profit,
        RankedSales.cs_item_sk
    FROM 
        RankedSales
    JOIN 
        item i ON RankedSales.cs_item_sk = i.i_item_sk
    WHERE 
        RankedSales.profit_rank <= 10
)
SELECT 
    w.w_warehouse_id,
    COUNT(DISTINCT T.i_item_id) AS unique_items_sold,
    SUM(T.total_net_profit) AS total_profit
FROM 
    TopProfitableItems T
JOIN 
    inventory inv ON T.cs_item_sk = inv.inv_item_sk 
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    w.w_warehouse_id
ORDER BY 
    total_profit DESC;
