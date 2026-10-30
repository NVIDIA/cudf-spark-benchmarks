
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        d.d_year,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ic.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ic ON hd.hd_income_band_sk = ic.ib_income_band_sk 
    GROUP BY 
        ws.ws_item_sk, d.d_year, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ic.ib_income_band_sk
),
RankedSales AS (
    SELECT 
        ws.ws_item_sk AS item_sk,
        total_quantity_sold,
        total_net_profit,
        d_year,
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        ib_income_band_sk,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS sales_rank
    FROM 
        SalesData ws
)
SELECT 
    r.d_year,
    r.item_sk,
    r.total_quantity_sold,
    r.total_net_profit,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.ib_income_band_sk
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year ASC, r.total_net_profit DESC;
