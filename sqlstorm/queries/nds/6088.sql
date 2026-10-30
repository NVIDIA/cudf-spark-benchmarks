
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_sales_price) AS average_sales_price
    FROM 
        catalog_sales cs
    JOIN 
        customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'S' 
        AND d.d_year = 2023 
        AND i.i_current_price BETWEEN 10 AND 100
    GROUP BY 
        cs.cs_item_sk
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
RankedSales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_quantity,
        sd.total_profit,
        ws.total_quantity_sold,
        ws.total_profit AS warehouse_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
    JOIN 
        WarehouseSales ws ON sd.cs_item_sk = ws.total_quantity_sold
)
SELECT 
    r.cs_item_sk,
    r.total_quantity,
    r.total_profit,
    r.warehouse_profit,
    r.profit_rank
FROM 
    RankedSales r
WHERE 
    r.profit_rank <= 10
ORDER BY 
    r.profit_rank;
