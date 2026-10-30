
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c 
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS average_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 3
        )
    GROUP BY 
        ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.cd_purchase_estimate,
        si.total_quantity,
        si.total_net_profit,
        si.average_net_paid,
        si.order_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        CustomerInfo ci
        LEFT JOIN SalesData si ON ci.c_customer_sk = si.ws_item_sk
        LEFT JOIN income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    s.total_quantity,
    s.total_net_profit,
    s.average_net_paid,
    s.order_count,
    CASE 
        WHEN s.average_net_paid IS NOT NULL THEN 'Active' 
        ELSE 'Inactive' 
    END AS status
FROM 
    FinalReport c
    LEFT JOIN SalesData s ON c.c_customer_sk = s.ws_item_sk
ORDER BY 
    c.c_last_name, 
    c.c_first_name, 
    s.total_net_profit DESC
LIMIT 100;
