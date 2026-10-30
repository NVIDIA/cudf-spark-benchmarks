WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_size DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p1.p_retailprice)
            FROM part p1
            WHERE p1.p_type LIKE '%fragile%'
        )
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    pi.p_name,
    si.s_name,
    co.c_name,
    co.order_count,
    co.total_spent,
    si.total_parts,
    si.max_acctbal
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierInfo si ON s.s_suppkey = si.s_suppkey
JOIN 
    RankedParts pi ON si.total_parts > 1 AND pi.brand_rank <= 3
JOIN 
    CustomerOrders co ON si.total_supplycost > co.total_spent * 0.1
WHERE 
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_suppkey = s.s_suppkey
        AND l.l_returnflag = 'R'
        AND l.l_shipmode NOT IN ('AIR', 'FOB')
        GROUP BY l.l_orderkey
        HAVING SUM(l.l_discount) > 0.2 * SUM(l.l_extendedprice)
    )
ORDER BY 
    co.total_spent DESC, si.total_parts ASC;
