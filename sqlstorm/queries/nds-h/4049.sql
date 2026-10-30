WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
TopNations AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS nation_rank
    FROM
        nation n
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_brand,
    ss.s_name AS supplier_name,
    ss.total_available_qty,
    ss.total_supply_cost,
    os.total_revenue,
    tn.n_name AS top_nation,
    tn.nation_rank
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    SupplierSummary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN
    OrderSummary os ON p.p_partkey = os.o_orderkey
JOIN
    TopNations tn ON os.o_custkey = tn.n_nationkey
WHERE
    (ss.total_available_qty IS NULL OR ss.total_available_qty > 10)
    AND (os.total_revenue IS NOT NULL AND os.total_revenue > 50000)
ORDER BY
    tn.nation_rank, p.p_partkey;
