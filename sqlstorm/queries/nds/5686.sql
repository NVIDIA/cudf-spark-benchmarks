
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND i.i_current_price > 20
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_sales_value
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
),
CustomerSegments AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity_sold,
    ts.total_sales_value,
    cs.customer_count,
    cs.avg_purchase_estimate
FROM 
    TopSales ts
JOIN 
    CustomerSegments cs ON cs.customer_count > 500
ORDER BY 
    ts.total_sales_value DESC;
