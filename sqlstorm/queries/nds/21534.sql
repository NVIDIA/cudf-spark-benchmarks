
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        ws.ws_item_sk
), return_data AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), combined_sales AS (
    SELECT 
        si.item_name,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_revenue, 0) AS total_revenue,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount
    FROM 
        (SELECT DISTINCT i.i_item_sk, i.i_product_name AS item_name FROM item i) si
    LEFT JOIN 
        sales_data sd ON si.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        return_data rd ON si.i_item_sk = rd.sr_item_sk
), ranked_sales AS (
    SELECT 
        item_name,
        total_quantity,
        total_revenue,
        total_returns,
        total_return_amount,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        combined_sales
), income_brackets AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS demographic_count,
        SUM(CASE WHEN ci.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer_info ci ON hd.hd_demo_sk = ci.c_current_cdemo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    rs.item_name,
    rs.total_quantity,
    rs.total_revenue,
    rs.total_returns,
    rs.total_return_amount,
    rs.revenue_rank,
    ib.demographic_count,
    ib.married_count,
    ib.avg_purchase_estimate
FROM 
    ranked_sales rs
LEFT JOIN 
    income_brackets ib ON (rs.total_revenue > ib.avg_purchase_estimate OR ib.avg_purchase_estimate IS NULL)
WHERE 
    (rs.total_returns - rs.total_quantity) < 0
ORDER BY 
    rs.revenue_rank, ib.demographic_count DESC NULLS LAST;
