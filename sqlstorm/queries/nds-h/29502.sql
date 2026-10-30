WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 5
),
SupplierData AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        REPLACE(s.s_address, 'Street', 'St.') AS s_address_short,
        s.s_phone, 
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
FilteredOrders AS (
    SELECT 
        od.o_orderkey, 
        od.part_count, 
        od.total_revenue,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
    WHERE 
        od.total_revenue > 5000
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    sd.s_name, 
    sd.s_address_short, 
    fo.total_revenue, 
    fo.revenue_rank
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierData sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    FilteredOrders fo ON fo.o_orderkey = ps.ps_partkey
WHERE 
    rp.rn = 1
ORDER BY 
    fo.total_revenue DESC
LIMIT 100;
