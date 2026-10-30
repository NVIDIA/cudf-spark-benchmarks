WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment,
        r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > 10000.00
), OrderedDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CONCAT('Order ', CAST(o.o_orderkey AS STRING), ' on ', CAST(o.o_orderdate AS STRING)) AS order_info
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
), LineitemAggregation AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_line_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    sd.s_name,
    sd.region_name,
    oa.o_orderdate,
    oa.order_info,
    la.total_revenue,
    la.total_line_items,
    sd.short_comment
FROM SupplierDetails sd
JOIN OrderedDetails oa ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > 50.00
    )
)
LEFT JOIN LineitemAggregation la ON oa.o_orderkey = la.l_orderkey
WHERE la.total_revenue IS NOT NULL
ORDER BY sd.region_name, oa.o_orderdate DESC, la.total_revenue DESC;