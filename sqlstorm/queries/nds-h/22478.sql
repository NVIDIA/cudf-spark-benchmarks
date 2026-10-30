WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        p.p_brand,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
HighDemandOrders AS (
    SELECT 
        l.l_partkey, 
        COUNT(*) AS order_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
    HAVING 
        COUNT(*) > (SELECT AVG(order_count) FROM (SELECT COUNT(*) AS order_count FROM lineitem GROUP BY l_partkey) AS avg_counts)
), 
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    r.r_name, 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT CASE WHEN cu.total_spent > 1000 THEN cu.c_custkey END) AS high_spender_count
FROM 
    RankedParts rp
JOIN 
    lineitem lp ON rp.p_partkey = lp.l_partkey
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    CustomerSpend cu ON o.o_custkey = cu.c_custkey
JOIN 
    supplier s ON s.s_suppkey = lp.l_suppkey
JOIN 
    partsupp ps ON ps.ps_partkey = lp.l_partkey AND ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rp.price_rank = 1 
    AND (lp.l_quantity * rp.p_retailprice - lp.l_discount) IS NOT NULL
    AND (s.s_acctbal > 0 OR s.s_comment IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 10000
ORDER BY 
    revenue DESC;
