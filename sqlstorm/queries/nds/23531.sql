
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 10
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        AVG(s.s_number_employees) AS avg_employees,
        MAX(s.s_tax_precentage) AS max_tax
    FROM 
        store s
    GROUP BY 
        s.s_store_sk
),
SalesAggregates AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_sales_price) AS total_sales_price,
        AVG(ss.ss_ext_tax) AS avg_ext_tax
    FROM 
        store_sales ss
    JOIN 
        TopItems ti ON ss.ss_item_sk = ti.ws_item_sk
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    si.s_store_sk,
    si.avg_employees,
    si.max_tax,
    sa.total_sales_price,
    sa.avg_ext_tax,
    CASE 
        WHEN sa.total_sales_price IS NULL THEN 'No Sales'
        WHEN sa.avg_ext_tax IS NULL THEN 'No Tax Info'
        ELSE 'Sales and Tax Info Available' 
    END AS status
FROM 
    StoreInfo si
LEFT JOIN 
    SalesAggregates sa ON si.s_store_sk = sa.ss_store_sk
WHERE 
    (si.avg_employees NOT BETWEEN 5 AND 100 OR si.max_tax > 0.15) 
    AND (sa.total_sales_price > 10000 OR sa.total_sales_price IS NULL)
ORDER BY 
    si.s_store_sk DESC;
