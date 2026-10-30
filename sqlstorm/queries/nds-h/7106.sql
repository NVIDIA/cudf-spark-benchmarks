
WITH supplier_costs AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        o.o_orderkey, o.o_custkey
)
SELECT
    os.o_orderkey,
    SUM(osc.total_cost) AS supplier_cost,
    os.total_revenue,
    os.lineitem_count
FROM
    order_summary os
JOIN
    lineitem l ON os.o_orderkey = l.l_orderkey
JOIN
    supplier_costs osc ON l.l_suppkey = osc.s_suppkey
GROUP BY
    os.o_orderkey, os.total_revenue, os.lineitem_count
HAVING
    SUM(osc.total_cost) < os.total_revenue
ORDER BY
    supplier_cost DESC, os.total_revenue DESC
LIMIT 50;
