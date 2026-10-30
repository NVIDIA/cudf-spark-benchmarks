
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate <= '1997-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_supplycost,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 2
)
SELECT 
    COALESCE(co.c_name, 'Unknown Customer') AS CustomerName,
    so.o_orderkey,
    so.o_totalprice,
    sp.p_name AS SupplierPartName,
    sp.ps_supplycost,
    su.parts_count,
    RANK() OVER (PARTITION BY co.c_name ORDER BY so.o_totalprice DESC) AS total_cost_rank,
    MAX(su.s_acctbal) AS max_supplier_balance
FROM 
    RankedOrders so
LEFT JOIN 
    CustomerOrders co ON so.o_orderkey = co.c_custkey
JOIN 
    SupplierParts sp ON so.o_orderkey = sp.ps_partkey
LEFT JOIN 
    FilteredSuppliers su ON sp.ps_partkey = su.s_suppkey
WHERE 
    so.o_orderstatus = 'O' 
    AND sp.rn = 1 
    AND (su.s_acctbal > 1000 OR su.s_acctbal IS NULL)
GROUP BY 
    co.c_name, so.o_orderkey, so.o_totalprice, sp.p_name, sp.ps_supplycost, su.parts_count
ORDER BY 
    co.c_name, total_cost_rank;
