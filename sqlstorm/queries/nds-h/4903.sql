
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        c.c_acctbal > 1000.00
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_lineitem_value,
    AVG(spc.supplier_count) AS average_supplier_count
FROM 
    CustomerRegion cr
LEFT JOIN 
    RankedOrders o ON cr.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartCounts spc ON l.l_partkey = spc.ps_partkey
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    COUNT(DISTINCT cr.c_custkey) > 5
ORDER BY 
    total_order_value DESC, cr.region_name, cr.nation_name;
