
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        w.w_warehouse_name,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450010
    AND ws.ws_net_profit IS NOT NULL
),
FilteredSales AS (
    SELECT 
        sd.w_warehouse_name,
        sd.c_first_name,
        sd.c_last_name,
        sd.cd_gender,
        sd.cd_marital_status,
        SUM(sd.ws_net_profit) AS total_net_profit,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM SalesData sd
    WHERE sd.rank <= 5
    GROUP BY 
        sd.w_warehouse_name,
        sd.c_first_name,
        sd.c_last_name,
        sd.cd_gender,
        sd.cd_marital_status
)
SELECT 
    fs.w_warehouse_name,
    COUNT(DISTINCT fs.c_first_name || ' ' || fs.c_last_name) AS customer_count,
    SUM(fs.total_net_profit) AS overall_net_profit,
    MAX(fs.avg_sales_price) AS highest_avg_price,
    CASE 
        WHEN SUM(fs.total_net_profit) IS NULL THEN 'No Profit Data'
        ELSE 'Profit Data Available'
    END AS profit_status
FROM FilteredSales fs
GROUP BY fs.w_warehouse_name
HAVING SUM(fs.total_net_profit) > 10000
ORDER BY overall_net_profit DESC
LIMIT 10;
