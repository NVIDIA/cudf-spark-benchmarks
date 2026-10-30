
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS revenue_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
ReturnMetrics AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), 
SalesWithDemographics AS (
    SELECT 
        ws.ws_item_sk,
        dm.cd_gender,
        dm.cd_marital_status,
        dm.cd_credit_rating,
        dm.hd_income_band_sk,
        COALESCE(rs.total_sold, 0) AS total_sold,
        COALESCE(rs.total_revenue, 0) AS total_revenue,
        COALESCE(rm.total_returns, 0) AS total_returns,
        COALESCE(rm.total_returned_value, 0) AS total_returned_value
    FROM 
        web_sales ws
    JOIN 
        Demographics dm ON ws.ws_bill_customer_sk = dm.c_customer_sk
    LEFT JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
    LEFT JOIN 
        ReturnMetrics rm ON ws.ws_item_sk = rm.sr_item_sk
)
SELECT 
    swd.cd_gender,
    swd.cd_marital_status,
    swd.hd_income_band_sk,
    COUNT(DISTINCT swd.ws_item_sk) AS distinct_items_sold,
    SUM(swd.total_sold) AS total_units_sold,
    SUM(swd.total_revenue) AS total_revenue,
    SUM(swd.total_returns) AS total_returns,
    SUM(swd.total_returned_value) AS total_returned_value,
    AVG(CASE WHEN swd.total_revenue > 0 THEN swd.total_sold / NULLIF(swd.total_revenue, 0) ELSE 0 END) AS avg_units_per_dollar
FROM 
    SalesWithDemographics swd
WHERE 
    swd.total_revenue > 0 OR swd.total_returns > 0
GROUP BY 
    swd.cd_gender, 
    swd.cd_marital_status, 
    swd.hd_income_band_sk
ORDER BY 
    total_revenue DESC;
