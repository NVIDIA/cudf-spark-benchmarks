WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part))
), 

SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(s.s_acctbal) AS max_supp_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
) 

SELECT 
    r.r_name, 
    n.n_name, 
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(l.l_extendedprice) AS max_extended_price,
    MIN(l.l_extendedprice) AS min_extended_price,
    COUNT(DISTINCT CASE WHEN l.l_shipmode LIKE '%AIR%' THEN l.l_orderkey END) AS air_orders
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
LEFT JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.rn <= 5
LEFT JOIN 
    SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
WHERE 
    o.o_orderstatus = 'F' AND 
    l.l_commitdate < l.l_receiptdate AND 
    EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = l.l_partkey AND ps.ps_availqty < sa.total_avail_qty)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l_extendedprice) FROM lineitem) OR 
    COUNT(DISTINCT o.o_orderkey) > 100
ORDER BY 
    total_revenue DESC, 
    total_orders ASC 
LIMIT 10;
