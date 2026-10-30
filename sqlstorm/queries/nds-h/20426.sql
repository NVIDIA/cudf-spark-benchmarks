
WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS part_count
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
filtered_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment,
        CASE 
            WHEN s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
            THEN 'Above Average'
            ELSE 'Below Average' 
        END AS acctbal_status
    FROM 
        supplier s
    WHERE 
        EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_suppkey = s.s_suppkey 
            AND ps.ps_availqty > 0
        )
),
recent_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderdate,
        o.o_shippriority,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
)
SELECT 
    r.r_name AS region_name, 
    ns.n_name AS nation_name, 
    ps.p_name, 
    fs.acctbal_status, 
    SUM(lo.l_quantity * (1 - lo.l_discount)) AS total_sales,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    MAX(lo.l_extendedprice) AS max_lineitem_price
FROM 
    ranked_parts ps
JOIN 
    filtered_suppliers fs ON fs.s_suppkey = ps.p_partkey
JOIN 
    lineitem lo ON lo.l_partkey = ps.p_partkey
JOIN 
    recent_orders ro ON lo.l_orderkey = ro.o_orderkey
JOIN 
    nation ns ON ns.n_nationkey = fs.s_nationkey
JOIN 
    region r ON r.r_regionkey = ns.n_regionkey
WHERE 
    ps.rnk <= 5 
    AND ro.o_orderstatus = 'F'
    AND (lo.l_returnflag IS NULL OR lo.l_returnflag NOT IN ('R', 'A'))
GROUP BY 
    r.r_name, ns.n_name, ps.p_name, fs.acctbal_status
HAVING 
    SUM(lo.l_quantity) > 1000
ORDER BY 
    total_sales DESC, 
    region_name ASC, 
    nation_name ASC;
