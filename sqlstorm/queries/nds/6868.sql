
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_order_number = cs.cs_order_number
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    GROUP BY 
        d.d_year
), 
IncomeSummary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    s.d_year,
    s.total_sales,
    s.total_orders,
    s.avg_net_profit,
    s.catalog_orders,
    s.total_returns,
    i.hd_income_band_sk,
    i.customer_count,
    i.avg_purchase_estimate
FROM 
    SalesSummary s
JOIN 
    IncomeSummary i ON s.total_sales > 1000000
ORDER BY 
    s.d_year DESC, s.total_sales DESC;
