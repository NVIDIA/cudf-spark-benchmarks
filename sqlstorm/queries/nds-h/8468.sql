WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        c.c_name, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate > DATE '1996-01-01' 
        AND o.o_orderstatus IN ('O', 'F', 'P')
), 

SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) as TotalAvailableQty, 
        SUM(ps.ps_supplycost) as TotalSupplyCost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        ps.ps_partkey
),

PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        sp.TotalAvailableQty, 
        sp.TotalSupplyCost
    FROM 
        part p
    JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)

SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.c_name, 
    pd.p_name, 
    pd.p_retailprice, 
    pd.TotalAvailableQty, 
    pd.TotalSupplyCost
FROM 
    RankedOrders ro
JOIN 
    lineitem li ON ro.o_orderkey = li.l_orderkey
JOIN 
    PartDetails pd ON li.l_partkey = pd.p_partkey
WHERE 
    ro.OrderRank <= 10
ORDER BY 
    ro.o_orderdate DESC, 
    ro.o_totalprice DESC;