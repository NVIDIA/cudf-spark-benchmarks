WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > 1000.00
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        MIN(l.l_shipdate) AS first_ship_date,
        MAX(l.l_shipdate) AS last_ship_date,
        (COUNT(l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R')) AS return_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        o.o_orderkey
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(ps.ps_availqty) > 50
)
SELECT
    ns.n_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    AVG(os.total_revenue) AS avg_revenue,
    SUM(fp.total_available) AS total_parts_available
FROM
    nation ns
LEFT JOIN
    customer cs ON ns.n_nationkey = cs.c_nationkey
LEFT JOIN
    OrderSummary os ON cs.c_custkey = os.o_orderkey
LEFT JOIN
    FilteredParts fp ON os.o_orderkey = fp.p_partkey
JOIN
    RankedSuppliers rs ON fp.p_partkey = rs.s_suppkey
WHERE
    ns.n_comment IS NOT NULL
GROUP BY
    ns.n_name
HAVING
    COUNT(DISTINCT cs.c_custkey) > 5
ORDER BY
    avg_revenue DESC;
