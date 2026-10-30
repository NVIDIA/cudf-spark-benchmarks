
WITH SalesData AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        i.i_item_id
),
TopSellingItems AS (
    SELECT 
        i_item_id,
        total_sold,
        total_revenue,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_sold DESC) AS rank
    FROM 
        SalesData
),
IncomeData AS (
    SELECT
        c.c_customer_id,
        h.hd_income_band_sk,
        h.hd_buy_potential,
        SUM(ws.ws_quantity) AS items_purchased
    FROM 
        customer c
    JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, h.hd_income_band_sk, h.hd_buy_potential
),
IncomeBandSums AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(items_purchased) AS total_items_purchased
    FROM 
        IncomeData
    JOIN 
        income_band ib ON IncomeData.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    tsi.i_item_id,
    tsi.total_sold,
    tsi.total_revenue,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ibs.total_items_purchased
FROM 
    TopSellingItems tsi
JOIN 
    IncomeBandSums ibs ON tsi.total_orders > 100
JOIN 
    income_band ib ON ibs.ib_income_band_sk = ib.ib_income_band_sk
WHERE 
    tsi.rank <= 10;
