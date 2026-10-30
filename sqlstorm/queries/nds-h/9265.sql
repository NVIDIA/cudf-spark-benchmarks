WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name AS nation_name
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE
        rs.rnk <= 5
),
SupplierParts AS (
    SELECT
        tp.s_suppkey,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM
        TopSuppliers tp
    JOIN
        partsupp ps ON tp.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem lp ON o.o_orderkey = lp.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
SupplierRevenue AS (
    SELECT
        sp.s_suppkey,
        sp.p_partkey,
        sp.p_name,
        SUM(co.revenue) AS total_revenue
    FROM
        SupplierParts sp
    JOIN
        CustomerOrders co ON sp.p_partkey = co.o_orderkey 
    GROUP BY
        sp.s_suppkey, sp.p_partkey, sp.p_name
)
SELECT
    sr.s_suppkey,
    sr.p_partkey,
    sr.p_name,
    sr.total_revenue,
    MAX(sp.ps_supplycost) AS max_supply_cost
FROM
    SupplierRevenue sr
JOIN
    SupplierParts sp ON sr.p_partkey = sp.p_partkey AND sr.s_suppkey = sp.s_suppkey
GROUP BY
    sr.s_suppkey, sr.p_partkey, sr.p_name, sr.total_revenue
ORDER BY
    total_revenue DESC, max_supply_cost ASC
LIMIT 10;