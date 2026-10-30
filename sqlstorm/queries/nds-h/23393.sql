
WITH  OrderedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(SA.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(CO.total_spent, 0) AS total_spent,
    ROUND((COALESCE(SA.total_avail_qty, 0) / NULLIF(COALESCE(CO.total_spent, 0), 0)), 2) AS availability_per_price
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierAggregates SA ON n.n_nationkey = SA.s_suppkey
LEFT JOIN 
    CustomerOrders CO ON n.n_nationkey = CO.c_custkey
WHERE 
    (COALESCE(SA.total_avail_qty, 0) > 100 OR COALESCE(CO.total_spent, 0) > 1000)
    AND (r.r_name IS NOT NULL OR r.r_name IS NULL)
ORDER BY 
    availability_per_price DESC, total_spent DESC
LIMIT 10;
