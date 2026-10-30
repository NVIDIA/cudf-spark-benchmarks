WITH RegionalSales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        r.r_name
),
SupplierParts AS (
    SELECT
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUM(ps.ps_availqty) AS total_available
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_name, p.p_name
),
TopSuppliers AS (
    SELECT
        supplier_name,
        part_name,
        total_available,
        RANK() OVER (PARTITION BY part_name ORDER BY total_available DESC) AS rank
    FROM
        SupplierParts
),
FinalReport AS (
    SELECT
        r.region_name,
        ts.supplier_name,
        ts.part_name,
        ts.total_available
    FROM
        RegionalSales r
    JOIN
        TopSuppliers ts ON r.region_name = (SELECT r2.r_name FROM region r2
                                             JOIN nation n2 ON r2.r_regionkey = n2.n_regionkey
                                             JOIN customer c2 ON c2.c_nationkey = n2.n_nationkey
                                             WHERE c2.c_custkey = 1) 
    WHERE
        ts.rank = 1
)
SELECT
    *
FROM
    FinalReport
ORDER BY
    region_name, supplier_name;