
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
NationSupplier AS (
    SELECT 
        n.n_name,
        s.s_suppkey,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
    HAVING 
        COUNT(o.o_orderkey) > 10
),
SupplierPart AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(RankedOrders.o_orderkey, 0) AS order_key,
    COUNT(DISTINCT CustomerSegment.c_custkey) AS customer_count,
    SUM(SupplierPart.total_supply_value) AS total_supply_value
FROM 
    part p
LEFT JOIN 
    RankedOrders ON p.p_partkey = RankedOrders.o_orderkey
LEFT JOIN 
    CustomerSegment ON p.p_partkey = CustomerSegment.c_custkey
LEFT JOIN 
    SupplierPart ON p.p_partkey = SupplierPart.ps_partkey
WHERE 
    p.p_size > 10 
    AND (p.p_mfgr LIKE 'Manufacturer%' OR p.p_comment IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, RankedOrders.o_orderkey
HAVING 
    COUNT(DISTINCT CustomerSegment.c_custkey) > 5
ORDER BY 
    total_supply_value DESC;
