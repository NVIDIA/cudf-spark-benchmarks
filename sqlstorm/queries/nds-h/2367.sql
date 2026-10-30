WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT
        s.*,
        RANK() OVER (PARTITION BY s.region_name ORDER BY s.total_supply_value DESC) AS supplier_rank
    FROM
        SupplierDetails s
)
SELECT
    c.c_name AS customer_name,
    c.c_acctbal AS customer_balance,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(tt.s_name) AS top_supplier
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN
    TopSuppliers tt ON l.l_suppkey = tt.s_suppkey AND tt.supplier_rank = 1
WHERE
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND l.l_returnflag = 'N'
GROUP BY
    c.c_name, c.c_acctbal
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY
    total_revenue DESC
LIMIT 10;