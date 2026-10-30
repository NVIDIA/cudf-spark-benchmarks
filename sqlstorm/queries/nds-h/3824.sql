
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
), 
HighValueItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    cu.c_name,
    COALESCE(r.r_name, 'Unknown') AS region,
    s.s_name AS top_supplier,
    COALESCE(h.total_value, 0) AS high_value,
    COUNT(DISTINCT cu.o_orderkey) AS order_count
FROM 
    CustomerOrders cu
LEFT JOIN 
    nation n ON mod(cu.o_orderkey, 10) = n.n_nationkey  
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
LEFT JOIN 
    RankedSuppliers s ON s.rank = 1 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand LIKE 'BrandA%'))
LEFT JOIN 
    HighValueItems h ON h.l_orderkey = cu.o_orderkey
WHERE 
    cu.o_orderstatus IN ('O', 'F')
GROUP BY 
    cu.c_name, r.r_name, s.s_name, h.total_value
ORDER BY 
    high_value DESC, order_count DESC;
