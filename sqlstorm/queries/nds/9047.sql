
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        wd.d_month_seq,
        wd.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    GROUP BY 
        ws.ws_item_sk, wd.d_month_seq, wd.d_year
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_orders,
        sd.total_quantity,
        sd.total_revenue,
        sd.total_discount,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_item_sk = cd.cd_demo_sk
)
SELECT 
    r.ws_item_sk,
    r.total_orders,
    r.total_quantity,
    r.total_revenue,
    r.total_discount,
    r.cd_gender,
    r.cd_marital_status
FROM 
    RankedSales r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.cd_gender, r.total_revenue DESC;
