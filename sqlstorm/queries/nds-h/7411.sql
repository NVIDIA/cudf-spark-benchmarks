WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        sum(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY sum(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, p.p_partkey
),
HighValueSuppliers AS (
    SELECT
        r.r_name,
        r.r_regionkey,
        SUM(rs.total_value) AS total_supplier_value
    FROM
        RankedSuppliers rs
    JOIN
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.supplier_rank = 1
    GROUP BY
        r.r_name, r.r_regionkey
)
SELECT
    r.r_name,
    r.total_supplier_value,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    HighValueSuppliers r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
GROUP BY
    r.r_name, r.total_supplier_value
ORDER BY
    r.total_supplier_value DESC;
