WITH supplier_totals AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        st.total_cost,
        st.num_parts,
        ROW_NUMBER() OVER (ORDER BY st.total_cost DESC) AS rn
    FROM
        supplier_totals st
    JOIN supplier s ON st.s_suppkey = s.s_suppkey
    WHERE
        st.total_cost > (SELECT AVG(total_cost) FROM supplier_totals)
),
order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_custkey) AS num_customers,
        o.o_orderstatus
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate >= '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT
    ts.s_name,
    ts.total_cost,
    osc.o_orderkey,
    osc.revenue,
    osc.num_customers,
    osc.o_orderstatus
FROM
    top_suppliers ts
LEFT JOIN order_summary osc ON ts.rn <= 5 AND osc.num_customers > 1000
WHERE
    ts.total_cost IS NOT NULL OR osc.revenue IS NOT NULL
ORDER BY
    ts.total_cost DESC, osc.revenue DESC;