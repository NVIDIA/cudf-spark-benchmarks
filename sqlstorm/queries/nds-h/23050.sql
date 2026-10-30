
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p 
    WHERE 
        p.p_size BETWEEN 1 AND 20 
        AND p.p_retailprice IS NOT NULL
),
CustomersWithOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SuppliersWithHighAvailability AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 500
)
SELECT 
    r.r_name AS region_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END), 0) AS total_returned_amount,
    AVG(cp.total_spent) AS average_customer_spent,
    MAX(p.p_retailprice) AS max_part_price,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomersWithOrders cp ON s.s_nationkey = cp.c_custkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    RankedParts p ON l.l_partkey = p.p_partkey AND p.price_rank <= 5
WHERE 
    r.r_name IS NOT NULL 
    AND EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_supplycost > 10 AND ps.ps_partkey = p.p_partkey)
GROUP BY 
    r.r_name
HAVING 
    MAX(p.p_retailprice) IS NOT NULL 
    OR COUNT(s.s_suppkey) > 0
    AND (COUNT(l.l_orderkey) > 10 OR AVG(cp.order_count) < 5)
ORDER BY 
    total_returned_amount DESC, r.r_name ASC;
