WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank,
        p.p_partkey,
        p.p_retailprice
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
TotalSales AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    WHERE
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY
        l.l_partkey
),
SupplierSales AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        t.total_sales
    FROM
        RankedSuppliers rs
    LEFT JOIN
        TotalSales t ON rs.p_partkey = t.l_partkey
    WHERE
        rs.rank = 1
)
SELECT
    ss.s_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    s.s_acctbal
FROM
    SupplierSales ss
JOIN
    supplier s ON ss.s_suppkey = s.s_suppkey
WHERE
    s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
ORDER BY
    total_sales DESC
LIMIT 10;