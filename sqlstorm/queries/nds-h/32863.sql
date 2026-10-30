
WITH  Sales_CTE AS (
    SELECT
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_nationkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
),
Supplier_CTE AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey
    HAVING
        SUM(ps.ps_availqty) IS NOT NULL
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_sales, 0) AS sales,
    COALESCE(a.total_availability, 0) AS availability,
    COALESCE(a.supplier_count, 0) AS supplier_count,
    r.r_name
FROM
    part p
LEFT OUTER JOIN Sales_CTE s ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100 ORDER BY ps.ps_supplycost DESC LIMIT 1)
LEFT JOIN Supplier_CTE a ON p.p_partkey = a.ps_partkey
JOIN
    nation n ON s.c_custkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    (COALESCE(a.total_availability, 0) > 0 OR COALESCE(s.total_sales, 0) > 0)
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
ORDER BY
    sales DESC, availability DESC, p.p_partkey
LIMIT 10;
