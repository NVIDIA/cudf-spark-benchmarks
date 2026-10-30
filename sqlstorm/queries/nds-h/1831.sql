WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL
),
TotalSales AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY
        l.l_partkey
),
AggregatedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(ts.total_revenue, 0) AS revenue,
        COALESCE(rs.rank, 0) AS supplier_rank
    FROM
        part p
    LEFT JOIN
        TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN
        RankedSuppliers rs ON p.p_partkey = rs.s_suppkey
)
SELECT
    ap.p_partkey,
    ap.p_name,
    ap.p_brand,
    ap.p_retailprice,
    ap.revenue,
    ap.supplier_rank
FROM
    AggregatedParts ap
WHERE
    (ap.supplier_rank IS NULL OR ap.supplier_rank <= 3)
    AND ap.revenue > (SELECT AVG(revenue) FROM AggregatedParts)
ORDER BY
    ap.revenue DESC
LIMIT 100 OFFSET 0;