
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' 
    GROUP BY 
        c.c_customer_id
), RankedSales AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        unique_items,
        avg_net_profit,
        total_discount,
        distinct_ship_modes,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.total_orders,
    r.unique_items,
    r.avg_net_profit,
    r.total_discount,
    r.distinct_ship_modes
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 100
ORDER BY 
    r.total_sales DESC;
