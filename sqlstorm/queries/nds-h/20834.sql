
WITH  SuppAPart AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.p_retailprice DESC) AS rn
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_size BETWEEN 1 AND 25
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns
    FROM
        part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey AND l.l_shipdate > DATE '1998-10-01' - INTERVAL '1' YEAR
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand
),
RegionSummary AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(c.c_acctbal) AS total_customer_balance
    FROM
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    f.order_count AS orders_last_year,
    f.avg_price AS average_price,
    r.total_customer_balance AS region_customer_balance,
    p.p_comment AS part_comment
FROM
    FilteredParts f
LEFT JOIN SuppAPart s ON f.p_partkey = s.ps_partkey AND s.rn = 1
LEFT JOIN RegionSummary r ON r.r_regionkey = (
    SELECT MIN(r_regionkey)
    FROM region
    WHERE r_name LIKE 'E%'
)
LEFT JOIN part p ON f.p_partkey = p.p_partkey
WHERE
    f.order_count IS NOT NULL
    OR f.avg_price IS NULL
ORDER BY 
    f.avg_price DESC NULLS LAST, 
    f.p_name ASC
LIMIT 50;
