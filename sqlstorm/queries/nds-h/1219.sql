WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartPrices AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        SUM(sp.s_acctbal) AS total_acct_balance
    FROM 
        supplier sp
    GROUP BY 
        sp.s_suppkey, sp.s_name
    HAVING 
        SUM(sp.s_acctbal) > 10000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) AS revenue,
    RANK() OVER (ORDER BY COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) DESC) AS revenue_rank,
    s.s_name,
    ro.o_orderstatus,
    ro.o_orderdate
FROM 
    part p
LEFT JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
LEFT JOIN 
    RankedOrders ro ON lp.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierPartPrices spp ON p.p_partkey = spp.ps_partkey
LEFT JOIN 
    TopSuppliers s ON spp.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size >= 10
    AND (p.p_retailprice * 0.9) > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, ro.o_orderstatus, ro.o_orderdate
HAVING 
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) > 5000
ORDER BY 
    revenue_rank, p.p_partkey;