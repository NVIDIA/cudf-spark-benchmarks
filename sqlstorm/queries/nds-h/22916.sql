WITH  order_totals AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
region_supplier AS (
    SELECT
        r.r_regionkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_qty,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY s.s_acctbal DESC) AS region_rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        r.r_regionkey, s.s_suppkey, s.s_name, s.s_acctbal
)
SELECT
    p.p_name,
    p.p_mfgr,
    rs.s_name AS supplier_name,
    rs.total_qty,
    ot.total_price AS order_total,
    CASE 
        WHEN ot.rn IS NOT NULL THEN 'Exists' 
        ELSE 'Not Exists' 
    END AS order_status,
    CONCAT('Supplier: ', rs.s_name, ', Region: ', r.r_name) AS supplier_region_info
FROM
    part p
LEFT JOIN
    region_supplier rs ON p.p_partkey = rs.s_suppkey
FULL OUTER JOIN
    order_totals ot ON rs.s_suppkey = ot.o_orderkey
JOIN
    region r ON rs.r_regionkey = r.r_regionkey
WHERE
    (rs.total_qty > 100 OR p.p_size BETWEEN 10 AND 100) 
    AND (ot.total_price IS NULL OR ot.total_price < 500)
ORDER BY
    p.p_partkey, rs.s_suppkey, ot.total_price DESC NULLS LAST;
