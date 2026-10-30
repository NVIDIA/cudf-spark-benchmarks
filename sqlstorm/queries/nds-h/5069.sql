WITH supplier_totals AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT
        st.s_suppkey,
        st.s_name,
        st.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY st.total_supply_cost DESC) AS rank
    FROM
        supplier_totals st
    WHERE
        st.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_totals)
),
customer_order_totals AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT
        cot.c_custkey,
        cot.c_name,
        cot.total_order_value,
        ROW_NUMBER() OVER (ORDER BY cot.total_order_value DESC) AS rank
    FROM
        customer_order_totals cot
    WHERE
        cot.total_order_value > (SELECT AVG(total_order_value) FROM customer_order_totals)
)
SELECT
    hvc.c_name AS high_value_customer,
    ts.s_name AS top_supplier,
    ts.total_supply_cost,
    hvc.total_order_value
FROM
    high_value_customers hvc
CROSS JOIN
    top_suppliers ts
WHERE
    hvc.rank <= 10 AND ts.rank <= 10
ORDER BY
    hvc.total_order_value DESC, ts.total_supply_cost DESC;
