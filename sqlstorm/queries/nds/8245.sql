
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        cbd.ca_state,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address cbd ON c.c_current_addr_sk = cbd.ca_address_sk
    JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
SalesSummary AS (
    SELECT 
        ws_sold_date_sk,
        ca_state,
        hd_income_band_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold
    FROM 
        SalesData
    GROUP BY 
        ws_sold_date_sk, ca_state, hd_income_band_sk
),
IncomeBandAnalysis AS (
    SELECT 
        ca_state,
        ib.ib_income_band_sk,
        SUM(total_quantity) AS quantity_by_income_band,
        SUM(total_sales) AS sales_by_income_band
    FROM 
        SalesSummary ss
    JOIN 
        income_band ib ON ss.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ca_state, ib.ib_income_band_sk
)
SELECT 
    ca_state,
    ib_income_band_sk,
    quantity_by_income_band,
    sales_by_income_band,
    RANK() OVER (PARTITION BY ca_state ORDER BY sales_by_income_band DESC) AS sales_rank,
    RANK() OVER (PARTITION BY ca_state ORDER BY quantity_by_income_band DESC) AS quantity_rank
FROM 
    IncomeBandAnalysis
ORDER BY 
    ca_state, sales_rank, quantity_rank;
