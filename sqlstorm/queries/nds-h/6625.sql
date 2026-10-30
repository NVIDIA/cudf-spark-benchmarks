WITH SupplierOrderDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
        AND s.s_acctbal > 5000
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal
),
RankedSuppliers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        SupplierOrderDetails
)
SELECT
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_quantity,
    rs.total_revenue,
    rs.order_count,
    rs.revenue_rank
FROM
    RankedSuppliers rs
JOIN
    supplier s ON rs.s_suppkey = s.s_suppkey
JOIN
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN
    region r ON ns.n_regionkey = r.r_regionkey
WHERE
    rs.revenue_rank <= 5
ORDER BY
    r.r_name, ns.n_name, rs.total_revenue DESC;