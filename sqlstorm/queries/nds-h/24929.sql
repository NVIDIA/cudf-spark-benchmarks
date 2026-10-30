WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
CustOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COALESCE(co.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        COALESCE(co.order_count, 0) > 2
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        r.r_name AS supplier_region,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) AS total_value,
    CASE 
        WHEN sr.supplier_region IS NULL THEN 'Unknown Region'
        ELSE sr.supplier_region
    END AS supplier_region,
    pt.p_name,
    pt.p_retailprice
FROM 
    TopCustomers tc
LEFT JOIN 
    lineitem lp ON tc.c_custkey = lp.l_orderkey
LEFT JOIN 
    partsupp ps ON lp.l_partkey = ps.ps_partkey
LEFT JOIN 
    RankedParts pt ON ps.ps_partkey = pt.p_partkey AND pt.rn = 1
LEFT JOIN 
    SupplierRegion sr ON lp.l_suppkey = sr.s_suppkey
GROUP BY 
    tc.c_custkey, tc.c_name, sr.supplier_region, pt.p_name, pt.p_retailprice
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) IS NOT NULL
ORDER BY 
    total_value DESC, tc.c_name ASC
LIMIT 10;
