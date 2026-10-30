WITH RecursiveTotal AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
),
SuppCount AS (
    SELECT
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
FinalResults AS (
    SELECT
        rt.p_partkey,
        rt.p_name,
        rt.total_revenue,
        s.s_name,
        COALESCE(sc.supplier_count, 0) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY rt.p_partkey ORDER BY rt.total_revenue DESC) AS rn
    FROM
        RecursiveTotal rt
    LEFT JOIN
        partsupp ps ON rt.p_partkey = ps.ps_partkey
    LEFT JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN
        SuppCount sc ON rt.p_partkey = sc.ps_partkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.total_revenue,
    CASE 
        WHEN f.rn = 1 THEN 'Top'
        ELSE 'Not Top' 
    END AS revenue_rank,
    f.s_name,
    f.supplier_count,
    CASE 
        WHEN f.total_revenue IS NULL OR f.total_revenue = 0 THEN 'No Revenue'
        ELSE 'Has Revenue'
    END AS revenue_status
FROM
    FinalResults f
WHERE
    f.supplier_count > 2
ORDER BY
    f.total_revenue DESC NULLS LAST
LIMIT 10;