WITH CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS total_returned_orders 
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
AggregateCustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        cr.total_returned_quantity,
        cr.total_returned_amount,
        cr.total_returned_orders
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
),
MonthlySales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM
        web_sales
    JOIN date_dim d ON d.d_date_sk = ws_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
FinalReport AS (
    SELECT
        aci.c_customer_id,
        aci.cd_gender,
        aci.cd_marital_status,
        aci.cd_education_status,
        aci.ca_city,
        aci.ca_state,
        aci.total_returned_quantity,
        aci.total_returned_amount,
        aci.total_returned_orders,
        ms.d_year,
        ms.d_month_seq,
        ms.total_sales_amount
    FROM
        AggregateCustomerInfo aci
    JOIN MonthlySales ms ON ms.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) 
        AND ms.d_month_seq = EXTRACT(MONTH FROM cast('2002-10-01' as date))
)
SELECT
    c_customer_id,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    total_returned_quantity,
    total_returned_amount,
    total_returned_orders,
    d_year,
    d_month_seq,
    total_sales_amount
FROM
    FinalReport
ORDER BY
    total_returned_amount DESC, total_returned_orders DESC;