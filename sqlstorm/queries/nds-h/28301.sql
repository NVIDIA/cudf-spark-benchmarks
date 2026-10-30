WITH RankedParts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_name LIKE '%rubber%'
),
RegionalSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE r.r_name IN ('ASIA', 'EUROPE')
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS order_linecount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    HAVING COUNT(l.l_orderkey) > 5
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rs.s_name, 
    rs.r_name, 
    fo.o_orderkey, 
    fo.o_totalprice, 
    fo.o_orderdate
FROM RankedParts rp
JOIN RegionalSuppliers rs ON rp.p_brand = SUBSTRING(rs.s_name, 1, 6)  
JOIN FilteredOrders fo ON fo.o_totalprice > rp.p_retailprice * 10
WHERE rp.rn = 1
ORDER BY rp.p_name, rs.r_name, fo.o_orderdate DESC;