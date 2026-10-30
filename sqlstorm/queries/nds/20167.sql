
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
),

TopSales AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
),

DateStats AS (
    SELECT 
        d_year,
        COUNT(DISTINCT d_date_sk) AS days_recorded,
        AVG(d_moy) AS avg_month_of_year
    FROM date_dim
    WHERE d_year BETWEEN 2020 AND 2023
    GROUP BY d_year
),

CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),

FilteredReturns AS (
    SELECT 
        c.c_customer_id,
        cr.return_count,
        cr.total_returned_amount
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returned_amount > (SELECT AVG(total_returned_amount) FROM CustomerReturns)
),

ShipModeAnalysis AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_ship_cost) AS total_shipping_cost
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
)

SELECT 
    'Top Selling Items' AS category,
    s.ss_store_sk,
    i.i_item_id,
    s.total_sales
FROM TopSales s
JOIN item i ON s.ss_item_sk = i.i_item_sk

UNION ALL 

SELECT 
    'Average Year Data' AS category,
    NULL AS ss_store_sk,
    NULL AS i_item_id,
    AVG(ds.days_recorded) AS total_sales
FROM DateStats ds

UNION ALL 

SELECT 
    'High Return Customers' AS category,
    NULL AS ss_store_sk,
    cr.c_customer_id,
    cr.return_count
FROM FilteredReturns cr

UNION ALL 

SELECT 
    'Shipping Mode Analysis' AS category,
    NULL AS ss_store_sk,
    sm.sm_ship_mode_id,
    sa.order_count
FROM ShipModeAnalysis sa
JOIN ship_mode sm ON sa.sm_ship_mode_id = sm.sm_ship_mode_id

ORDER BY category, total_sales DESC NULLS LAST;
