WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sp.total_available, 0) AS total_available_quantity,
    COALESCE(sp.max_cost, 0) AS max_supply_cost,
    CASE 
        WHEN hvo.o_orderkey IS NOT NULL THEN 'High Value Order' 
        ELSE 'No High Value' 
    END AS order_status,
    COUNT(hvo.o_orderkey) OVER (PARTITION BY p.p_partkey) AS order_count
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.total_value > p.p_retailprice
WHERE 
    (p.p_size IS NULL OR p.p_size > 50)
    AND (p.p_comment NOT LIKE '%special%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_partkey, 
    total_available_quantity DESC, 
    order_count DESC;