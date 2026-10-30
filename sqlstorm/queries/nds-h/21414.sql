WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name
    FROM 
        SupplierDetails sd
    WHERE 
        sd.avg_supply_cost > (SELECT AVG(avg_supply_cost) FROM SupplierDetails)
),
CustomerOrders AS (
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
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
QualifiedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.price_rank,
        ps.ps_availqty
    FROM 
        RankedParts rp
    LEFT JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    WHERE 
        rp.price_rank <= 3
)
SELECT 
    co.c_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    COUNT(DISTINCT qp.p_partkey) AS purchased_parts,
    SUM(qp.ps_availqty) AS total_avail_qty
FROM 
    CustomerOrders co
JOIN 
    orders o ON co.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    QualifiedParts qp ON l.l_partkey = qp.p_partkey
WHERE 
    co.order_count > 5 
    AND EXISTS (SELECT 1 FROM HighValueSuppliers hvs WHERE hvs.s_suppkey = l.l_suppkey)
GROUP BY 
    co.c_name
HAVING 
    SUM(CASE WHEN l.l_discount < 0.1 THEN l.l_extendedprice END) IS NOT NULL
ORDER BY 
    total_orders DESC
LIMIT 10;
